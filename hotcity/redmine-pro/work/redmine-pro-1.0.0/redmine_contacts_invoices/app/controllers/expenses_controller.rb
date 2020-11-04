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

class ExpensesController < ApplicationController
  unloadable

  before_action :find_expense_project, :only => [:create, :new]
  before_action :find_expense, :only => [:edit, :show, :destroy, :update]
  before_action :bulk_find_expenses, :only => [:bulk_update, :bulk_edit, :bulk_destroy, :context_menu]
  before_action :authorize, :except => [:index, :edit, :update, :destroy]
  before_action :find_optional_project, :only => [:index]
  before_action :calc_statistics, :only => [:index, :edit]

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :attachments
  helper :contacts
  helper :invoices
  helper :custom_fields
  helper :timelog
  helper :sort
  helper :context_menus
  helper :crm_queries
  helper :queries
  include ExpensesHelper
  include InvoicesHelper
  include ContactsHelper
  include SortHelper
  include QueriesHelper
  include CrmQueriesHelper

  def index
    retrieve_crm_query('expense')
    sort_init(@query.sort_criteria.empty? ? [['expense_date', 'desc']] : @query.sort_criteria)
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

      @expense_amount = @query.expense_amount

      @expenses_count = @query.object_count
      @expenses_scope = @query.objects_scope
      @expenses_pages = Paginator.new @expenses_count, @limit, params['page']
      @offset ||= @expenses_pages.offset
      @expense_count_by_group = @query.object_count_by_group
      @expenses = @query.results_scope(
        :include => [{ contact: [:avatar, :projects, :address] }, :author],
        :search => params[:search],
        :order => sort_clause,
        :limit  =>  @limit,
        :offset =>  @offset
      )

      respond_to do |format|
        format.html
        format.api
        format.csv { send_data(expenses_to_csv(@expenses), :type => 'text/csv; header=present', :filename => 'expenses.csv') }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'expenses/index', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def edit
  end

  def show
  end

  def new
    @expense = Expense.new
    @expense.expense_date = Date.today
    @expense.currency = ContactsSetting.default_currency
  end

  def create
    @expense = Expense.new
    @expense.safe_attributes = params[:expense]
    @expense.project ||= @project
    @expense.author = User.current
    if @expense.save
      Attachment.attach_files(@expense, (params[:attachments] || (params[:expense] && params[:expense][:uploads])))
      render_attachment_warning_if_needed(@expense)

      flash[:notice] = l(:notice_successful_create)

      respond_to do |format|
        format.html { redirect_to :action => 'index', :project_id => @expense.project }
        format.api  { render :action => 'show', :status => :created, :location => expense_url(@expense) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@expense) }
      end
    end
  end

  def update
    (render_403; return false) unless @expense.editable_by?(User.current)
    @expense.safe_attributes = params[:expense]
    if @expense.save
      Attachment.attach_files(@expense, (params[:attachments] || (params[:expense] && params[:expense][:uploads])))
      render_attachment_warning_if_needed(@expense)
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to :action => 'index', :project_id => @expense.project }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@expense) }
      end
    end
  end

  def destroy
    (render_403; return false) unless @expense.destroyable_by?(User.current)
    if @expense.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    respond_to do |format|
      format.html { redirect_to :action => 'index', :project_id => @expense.project }
      format.api  { head :ok }
    end
  end

  def context_menu
    @expense = @expenses.first if @expenses.size == 1
    @can = { edit: @expenses.collect { |c| c.editable_by?(User.current) }.inject { |memo, d| memo && d },
             delete: @expenses.collect { |c| c.destroyable_by?(User.current) }.inject { |memo, d| memo && d } }

    @back = back_url
    render :layout => false
  end

  def bulk_update
    unsaved_expense_ids = []
    @expenses.each do |expense|
      expense.safe_attributes = parse_params_for_bulk_expense_attributes(params)
      unsaved_expense_ids << expense.id unless expense.save
    end
    set_flash_from_bulk_contact_save(@expenses, unsaved_expense_ids)
    redirect_back_or_default(:controller => 'expenses', :action => 'index', :project_id => @project)
  end

  def bulk_destroy
    @expenses.each do |expense|
      begin
        expense.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
        # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default(:action => 'index', :project_id => @project) }
      format.api  { head :ok }
    end
  end

  private

  def calc_statistics
    current_project = @invoice ? nil : @project
    contact_id = @invoice ? @invoice.contact_id : nil

    @current_week_sum = Expense.sum_by_period("current_week", current_project, contact_id)
    @last_week_sum = Expense.sum_by_period("last_week", current_project, contact_id)
    @current_month_sum = Expense.sum_by_period("current_month", current_project, contact_id)
    @last_month_sum = Expense.sum_by_period("last_month", current_project, contact_id)
    @current_year_sum = Expense.sum_by_period("current_year", current_project, contact_id)

    @draft_status_sum, @draft_status_count = Expense.sum_by_status(Expense::DRAFT_EXPENSE, current_project, contact_id)
    @new_status_sum, @new_status_count = Expense.sum_by_status(Expense::NEW_EXPENSE, current_project, contact_id)
    @billed_status_sum, @billed_status_count = Expense.sum_by_status(Expense::BILLED_EXPENSE, current_project, contact_id)
    @paid_status_sum, @paid_status_count = Expense.sum_by_status(Expense::PAID_EXPENSE, current_project, contact_id)
  end

  def parse_params_for_bulk_expense_attributes(params)
    attributes = (params[:expense] || {}).reject { |_k, v| v.blank? }
    attributes.keys.each { |k| attributes[k] = '' if attributes[k] == 'none' }
    attributes[:custom_field_values].reject! { |_k, v| v.blank? } if attributes[:custom_field_values]
    attributes
  end

  def bulk_find_expenses
    @expenses = Expense.eager_load(:project).where(:id => params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @expenses.empty?
    if @expenses.detect {|expense| !expense.visible?}
      deny_access
      return
    end
    @projects = @expenses.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_expense_project
    project_id = params[:project_id] || (params[:expense] && params[:expense][:project_id])
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_expense
    @expense = Expense.eager_load([:project, :contact]).find(params[:id])
    @project ||= @expense.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
