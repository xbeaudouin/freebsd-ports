# This file is a part of Redmine Invoices (redmine_contacts_invoices) plugin,
# invoicing plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# https://www.redmineup.com/
#
# redmine_contacts_invoices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts_invoices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts_invoices.  If not, see <http://www.gnu.org/licenses/>.

class InvoicesController < ApplicationController
  unloadable

  before_action :find_invoice_project, :only => [:create, :new]
  before_action :find_invoice, :only => [:edit, :show, :destroy, :update, :client_view]
  before_action :bulk_find_invoices, :only => [:bulk_update, :bulk_edit, :bulk_destroy, :context_menu]
  before_action :authorize, :except => [:index, :edit, :update, :destroy, :auto_complete, :client_view, :recurring]
  before_action :find_optional_project, :only => [:index]
  before_action :calc_statistics, :only => [:index, :show]
  before_action :find_optional_template, :only => [:show, :client_view]
  skip_before_action :check_if_login_required, :only => [:client_view]
  before_action :authorize_public, :only => [:client_view]

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :attachments
  helper :issues
  helper :contacts
  helper :timelog
  helper :watchers
  helper :custom_fields
  helper :sort
  helper :context_menus
  helper :crm_queries
  helper :queries
  helper :calendars
  helper :invoice_payments
  include SortHelper
  include InvoicesHelper
  include ContactsHelper
  include QueriesHelper
  include CrmQueriesHelper
  include InvoicePaymentsHelper

  def index
    retrieve_crm_query('invoice')
    sort_init(@query.sort_criteria.empty? ? [['invoice_date', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
      when 'csv', 'pdf'
        @limit = Setting.issues_export_limit.to_i
      when 'atom'
        @limit = Setting.feeds_limit.to_i
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = per_page_option
      end

      @invoiced_amount = @query.invoiced_amount
      @paid_amount = @query.paid_amount
      @due_amount = @query.due_amount

      @invoices_count = @query.object_count
      @invoices_scope = @query.objects_scope
      if invoices_list_style == 'crm_calendars/crm_calendar'
        retrieve_crm_calendar(:start_date_field => "invoice_date", :due_date_field => 'due_date')
        @calendar.events = @query.results_scope(
          :include => [:contact],
          :search => params[:search],
          :conditions => ['((invoice_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))', @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
        )
      end

      @invoices_pages = Paginator.new @invoices_count, @limit, params['page']
      @offset ||= @invoices_pages.offset
      @invoice_count_by_group = @query.object_count_by_group
      @invoices = @query.results_scope(
        :include => [{ :contact => [:avatar, :projects, :address] }, :author],
        :search => params[:search],
        :order => sort_clause,
        :limit  =>  @limit,
        :offset =>  @offset
      )

      respond_to do |format|
        format.html
        format.api
        format.csv { send_data(invoices_to_csv(@invoices), :type => 'text/csv; header=present', :filename => 'invoices.csv') }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'invoices/index', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show
    @invoice_lines = @invoice.lines || []
    @payments = @invoice.payments
    @comments = @invoice.comments.to_a
    @comments.reverse! if User.current.wants_comments_in_reverse_order?
    respond_to do |format|
      format.html
      format.api
      format.pdf do
        send_data(invoice_to_pdf(@invoice), :type => 'application/pdf', :filename => @invoice.filename, :disposition => 'inline')
      end
    end
  end

  def new
    @invoice = Invoice.new
    @invoice.number = Invoice.generate_invoice_number(@project)
    @invoice.invoice_date = Date.today
    @invoice.contact = Contact.find_by_id(params[:contact_id]) if params[:contact_id]
    @invoice.assigned_to = User.current
    @invoice.currency ||= ContactsSetting.default_currency
    @invoice.copy_from(params[:copy_from]) if params[:copy_from]
    if params[:issues_ids]
      @invoice.lines_from_issues(params[:issues_ids], params[:line_grouping], :project => @project)
    elsif params[:time_entries_ids]
      @invoice.lines_from_time_entries(params[:time_entries_ids], params[:line_grouping], :project => @project)
    elsif params[:copy_from_object]
      @invoice.copy_from_object(params[:copy_from_object], :project => @project)
    end

    @invoice.lines.build if @invoice.lines.blank?

    @last_invoice_number = Invoice.last.try(:number)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create
    @invoice = Invoice.new
    @invoice.safe_attributes = params[:invoice]
    @invoice.project ||= @project
    @invoice.author = User.current
    @invoice.number = Invoice.apply_invoice_macros(@invoice.number)
    @invoice.subject = Invoice.apply_invoice_macros(@invoice.subject)
    if @invoice.save
      @invoice.lines.each(&:save)
      Attachment.attach_files(@invoice, (params[:attachments] || (params[:invoice] && params[:invoice][:uploads])))
      render_attachment_warning_if_needed(@invoice)
      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.html { redirect_to :action => 'show', :id => @invoice }
        format.api  { render :action => 'show', :status => :created, :location => invoice_url(@invoice) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@invoice) }
      end
    end
  end

  def edit
    (render_403; return false) unless @invoice.editable_by?(User.current)
    @invoice_lines = @invoice.lines || []
    respond_to do |format|
      format.html {}
      format.xml  {}
    end
  end

  def update
    (render_403; return false) unless @invoice.editable_by?(User.current)
    @invoice.safe_attributes = params[:invoice].merge(:discount => params[:invoice][:discount].to_f)
    if @invoice.save
      @invoice.lines.each(&:save)
      Attachment.attach_files(@invoice, (params[:attachments] || (params[:invoice] && params[:invoice][:uploads])))
      render_attachment_warning_if_needed(@invoice)
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to :action => 'show', :id => @invoice }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@invoice) }
      end
    end
  end

  def destroy
    (render_403; return false) unless @invoice.destroyable_by?(User.current)
    if @invoice.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    respond_to do |format|
      format.html { redirect_to :action => 'index', :project_id => @project }
      format.api  { head :ok }
    end
  end
  def client_view
    @payments = @invoice.payments
    @comments = @invoice.comments.to_a
    @comments.reverse! if User.current.wants_comments_in_reverse_order?

    respond_to do |format|
      format.html do
        if @invoice.custom_template
          @html_preview = true
          render((Rails.version < '5.1' ? :text : :plain) => liquidize_invoice(@invoice), :layout => 'invoices.pdf')
        else
          send_data(invoice_to_pdf(@invoice), :type => 'application/pdf', :filename => "invoice-#{@invoice.number}.pdf", :disposition => 'inline')
        end
      end
      format.pdf { send_data(invoice_to_pdf(@invoice), :type => 'application/pdf', :filename => "invoice-#{@invoice.number}.pdf", :disposition => 'inline') }
    end
  end

  def send_mail
  end

  def context_menu
    @invoice = @invoices.first if @invoices.size == 1
    @invoice_ids = @invoices.map(&:id).sort
    @can = { :edit =>  @invoices.collect { |c| c.editable_by?(User.current) }.inject { |memo, d| memo && d },
             :delete => @invoices.collect { |c| c.destroyable_by?(User.current) }.inject { |memo, d| memo && d },
             :create => User.current.allowed_to?(:add_invoices, @projects),
             :change_status => @invoices.collect { |c| !c.is_paid? }.inject { |memo, d| memo && d },
             :send => User.current.allowed_to?(:send_invoices, @invoices.first.project),
             :pdf => User.current.allowed_to?(:view_invoices, @projects) }
    @back = back_url
    render :layout => false
  end

  def bulk_destroy
    @invoices.each do |invoice|
      begin
        invoice.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
        # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default(:action => 'index', :project_id => params[:project_id]) }
      format.api  { head :ok }
    end
  end

  def bulk_update
    unsaved_invoice_ids = []
    @invoices.each do |invoice|
      invoice.safe_attributes = parse_params_for_bulk_invoice_attributes(params)
      unsaved_invoice_ids << invoice.id unless invoice.save
    end
    set_flash_from_bulk_contact_save(@invoices, unsaved_invoice_ids)
    redirect_back_or_default(:controller => 'invoices', :action => 'index', :project_id => @project)
  end

  def auto_complete
    @invoices = []
    q = (params[:q] || params[:term]).to_s.strip
    scope = Invoice.visible
    scope = scope.limit(params[:limit] || 10)
    scope = scope.where(:currency => params[:currency]) if params[:currency]
    scope = scope.where(:status_id => params[:status_id]) if params[:status_id]
    scope = scope.where(:project_id => params[:project_id]) if params[:project_id]
    scope = scope.live_search(q) if q.present?
    @invoices = scope.order(:number)

    render((Rails.version < '5.1' ? :text : :plain) => @invoices.map { |invoice|
      { 'id' => invoice.id,
        'label' => "##{invoice.number} - #{format_date(invoice.invoice_date)}: (#{invoice.amount_to_s})",
        'value' => invoice.id }
    }.to_json)
  end
  def recurring
    RecurringInvoicesService.new.process_invoices
    render :nothing => true, :status => :ok
  end

  private

  def calc_statistics
    current_project = @invoice ? nil : @project
    contact_id = @invoice ? @invoice.contact_id : nil

    @current_week_sum = Invoice.sum_by_period('current_week', current_project, contact_id)
    @last_week_sum = Invoice.sum_by_period('last_week', current_project, contact_id)
    @current_month_sum = Invoice.sum_by_period('current_month', current_project, contact_id)
    @last_month_sum = Invoice.sum_by_period('last_month', current_project, contact_id)
    @current_year_sum = Invoice.sum_by_period('current_year', current_project, contact_id)

    @status_stat = {}

    @draft_status_sum, @draft_status_count = Invoice.sum_by_status(Invoice::DRAFT_INVOICE, current_project, contact_id)
    @estimate_status_sum, @estimate_status_count = Invoice.sum_by_status(Invoice::ESTIMATE_INVOICE, current_project, contact_id)
    @sent_status_sum, @sent_status_count = Invoice.sum_by_status(Invoice::SENT_INVOICE, current_project, contact_id)
    @paid_status_sum, @paid_status_count = Invoice.sum_by_status(Invoice::PAID_INVOICE, current_project, contact_id)
    @canceled_status_sum, @canceled_status_count = Invoice.sum_by_status(Invoice::CANCELED_INVOICE, current_project, contact_id)
  end

  def last_comments
    @last_comments = []
  end

  def find_invoice_project
    project_id = params[:project_id] || (params[:invoice] && params[:invoice][:project_id])
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Filter for bulk issue invoices
  def bulk_find_invoices
    @invoices = Invoice.eager_load(:project).where(:id => params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @invoices.empty?
    raise Unauthorized unless @invoices.all?(&:visible?)
    @projects = @invoices.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoice
    @invoice = Invoice.eager_load([:project, :contact]).find(params[:id])
    @project ||= @invoice.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def parse_params_for_bulk_invoice_attributes(params)
    attributes = (params[:invoice] || {}).reject { |_k, v| v.blank? }
    attributes.keys.each { |k| attributes[k] = '' if attributes[k] == 'none' }
    attributes[:custom_field_values].reject! { |_k, v| v.blank? } if attributes[:custom_field_values]
    attributes
  end
  def find_optional_template
    @invoice_template = InvoiceTemplate.find(params[:invoice_template_id]) if params[:invoice_template_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_public
    allow = true && !params[:token].blank?
    allow &&= (@invoice.token == params[:token]) && InvoicesSettings.public_links?
    render_404 unless allow
  end
end
