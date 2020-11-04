class HelpdeskTicketsController < ApplicationController
  unloadable

  before_action :find_issue, except: [:index, :create]
  before_action :find_project, except: [:index]
  before_action :authorize, except: [:index]
  before_action :find_helpdesk_ticket, only: [:show, :edit, :update, :destroy]
  before_action :find_optional_project, only: [:index]

  accept_api_auth :index, :create, :show, :update, :destroy

  helper :helpdesk
  helper :helpdesk_api
  helper :attachments
  helper :queries
  include QueriesHelper

  def index
    retrieve_query(HelpdeskTicketQuery)

    if @query.valid?
      respond_to do |format|
        format.api  {
          @offset, @limit = api_offset_and_limit
          @tickets_count = @query.tickets_count
          @tickets = @query.tickets(offset: @offset, limit: @limit)
          Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
        }
        format.any { head 200 }
      end
    else
      respond_to do |format|
        format.any(:atom, :csv, :pdf) { head 422 }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create
    return unless validate_create_params

    @issue = Issue.new
    @issue.project = @project
    @issue.author ||= User.current
    @issue.safe_attributes = params[:helpdesk_ticket][:issue]

    @contact = Contact.find_by_emails([params[:helpdesk_ticket][:contact][:email]]).first
    unless @contact
      @contact = Contact.new
      @contact.safe_attributes = params[:helpdesk_ticket][:contact]
    end
    @contact.projects << @project unless @contact.projects.include?(@project)

    @helpdesk_ticket = HelpdeskTicket.new(ticket_date: Time.now, customer: @contact, is_incoming: true, issue: @issue)
    @helpdesk_ticket.safe_attributes = params[:helpdesk_ticket].except(:issue, :contact)
    @helpdesk_ticket.from_address = @contact.primary_email
    @helpdesk_ticket.source = find_ticket_source

    @issue.helpdesk_ticket = @helpdesk_ticket
    @issue.assigned_to = @contact.find_assigned_user(@project, @issue.assigned_to)
    @issue.save_attachments(params[:helpdesk_ticket][:attachments] || (params[:helpdesk_ticket][:issue] && params[:helpdesk_ticket][:issue][:uploads]))

    if @issue.save
      process_helpdesk_send_as
      HelpdeskTicket.autoclose(@project)
      return render_api_view(action: :create, status: :created)
    else
      return render_api_error(message: @issue.errors.full_messages)
    end
  rescue Exception => e
    render_api_error(message: "#{e.message} (#{e.backtrace.first})")
  end

  def show
    @show_form = 'false'
    respond_to do |format|
      format.js
      format.api
    end
  end

  def edit
    @helpdesk_ticket = @issue.helpdesk_ticket || @issue.build_helpdesk_ticket(ticket_date: Time.now)

    @show_form = 'true'
    respond_to do |format|
      format.js
    end
  end

  def update
    @helpdesk_ticket.safe_attributes = params[:helpdesk_ticket]
    if params[:helpdesk_ticket][:cc_address]
      cc_address = params[:helpdesk_ticket][:cc_address]
      cc_address = cc_address.reject(&:empty?).join(',') if cc_address.is_a?(Array)
      @helpdesk_ticket.cc_address = cc_address
    end
    if params[:helpdesk_ticket][:from_address].present?
      @helpdesk_ticket.customer = HelpdeskMailSupport.create_contact_from_address(params[:helpdesk_ticket][:from_address],
                                                                                  params[:helpdesk_ticket][:from_address],
                                                                                  @project)
    else
      @helpdesk_ticket.from_address = @helpdesk_ticket.customer.try(:primary_email)
    end
    @helpdesk_ticket.source = find_ticket_source if params[:helpdesk_ticket][:source]

    if @helpdesk_ticket.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_back_or_default(issue_path(@issue)) }
        format.api  { render_api_view(action: :show, status: 200) }
      end
    else
      flash[:error] = @helpdesk_ticket.errors.full_messages.flatten.join("\n")
      respond_to do |format|
        format.html { redirect_back_or_default(issue_path(@issue)) }
        format.api  { render_api_error(message: @issue.errors.full_messages) }
      end
    end
  end

  def destroy
    if @helpdesk_ticket.destroy
      flash[:notice] = l(:notice_successful_delete)
      respond_to do |format|
        format.html { redirect_back_or_default(issue_path(@issue)) }
        format.api { render_api_view(status: :no_content) }
      end
    else
      flash[:error] = l(:notice_unsuccessful_save)
      respond_to do |format|
        format.html { redirect_back_or_default(issue_path(@issue)) }
        format.api  { render_api_error(message: @helpdesk_ticket.errors.full_messages) }
      end
    end
  end

  private

  def find_issue
    #TODO: Remove params[:issue_id] when new API will be applied
    @issue = Issue.find(params[:issue_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render_api_error(message: 'Issue not found', status: :not_found)
  end

  def find_project
    return @project = @issue.project if @issue

    project_id = params[:helpdesk_ticket] && params[:helpdesk_ticket][:issue] && params[:helpdesk_ticket][:issue][:project_id]
    @project = Project.find_by_param(project_id)
  rescue ActiveRecord::RecordNotFound
    return render_api_error(message: 'Project not found', status: :not_found) unless @project
  end

  def find_helpdesk_ticket
    @helpdesk_ticket = @issue.helpdesk_ticket
    @helpdesk_ticket ||= @issue.build_helpdesk_ticket(ticket_date: Time.now) unless request.format.api?
    return render_api_error(message: 'Helpdesk ticket not found', status: :not_found) unless @helpdesk_ticket
  end

  def validate_create_params
    return render_api_error(message: 'HelpdeskTicket params cannot be blank') if params[:helpdesk_ticket].blank?
    return render_api_error(message: 'Issue params cannot be blank') if params[:helpdesk_ticket][:issue].blank?
    return render_api_error(message: 'Contact params cannot be blank') if params[:helpdesk_ticket][:contact].blank?
    return render_api_error(message: 'Contact should have email address') if params[:helpdesk_ticket][:contact][:email].blank?

    true
  end

  def find_ticket_source
    case params[:helpdesk_ticket][:source]
    when 'email', '0'
      HelpdeskTicket::HELPDESK_EMAIL_SOURCE
    when 'web', '1'
      HelpdeskTicket::HELPDESK_WEB_SOURCE
    when 'phone', '2'
      HelpdeskTicket::HELPDESK_PHONE_SOURCE
    when 'twitter', '3'
      HelpdeskTicket::HELPDESK_TWITTER_SOURCE
    when 'conversation', '4'
      HelpdeskTicket::HELPDESK_CONVERSATION_SOURCE
    else
      HelpdeskTicket::HELPDESK_WEB_SOURCE
    end
  end

  def process_helpdesk_send_as
    return unless @issue && User.current.allowed_to?(:send_response, @project)

    case params[:helpdesk_ticket][:send_as]
    when 'auto_answer'
      HelpdeskMailer.auto_answer(@issue.customer, @issue)
    when 'initial_message'
      if msg = HelpdeskMailer.initial_message(@issue.customer, @issue)
        @issue.helpdesk_ticket.message_id = msg.message_id
        @issue.helpdesk_ticket.is_incoming = false
        @issue.helpdesk_ticket.from_address = @issue.helpdesk_ticket.from_address || @issue.customer.primary_email
        @issue.helpdesk_ticket.save
      end
    else
      HelpdeskMailer.auto_answer(@contact, @issue) if HelpdeskSettings['helpdesk_send_notification', @project].to_i > 0
    end
  end

  def render_api_view(opts)
    status = opts[:status] || 200
    respond_to do |format|
      format.api  do
        return head status if opts[:action].blank?
        render action: opts[:action], status: status
      end
      format.any { head status }
    end
    true
  end

  def render_api_error(opts)
    @message = opts[:message]
    @error_messages = [opts[:message]]
    @status = opts[:status] || :unprocessable_entity
    respond_to do |format|
      format.html do
        render_404
      end
      format.api do
        render template: 'common/error_messages.api', status: @status
      end
      format.any { head @status }
    end
    false
  end
end
