class JournalMessagesController < ApplicationController
  before_action :find_issue
  before_action :find_project
  before_action :authorize

  accept_api_auth :create

  helper :helpdesk
  helper :helpdesk_api
  helper :attachments

  def create
    return unless validate_create_params

    journal = @issue.init_journal(User.current)
    if params[:journal_message][:status_id].present?
      issue_status = IssueStatus.where(id: params[:journal_message][:status_id]).first
      @issue.status_id = issue_status.id if issue_status
    end
    journal.notes = params[:journal_message][:content]
    @issue.save_attachments(params[:attachments] || params[:journal_message][:uploads])

    if @issue.save
      contact = @issue.customer
      @journal_message = JournalMessage.create!(from_address: params[:journal_message][:from_address],
                                                to_address: params[:journal_message][:to_address] || contact.primary_email.downcase,
                                                cc_address: params[:journal_message][:cc_address],
                                                bcc_address: params[:journal_message][:bcc_address],
                                                is_incoming: false,
                                                message_date: Time.now,
                                                contact: contact,
                                                journal: journal)
      @journal_message.update_attributes(message_id: HelpdeskMailer.issue_response(contact, journal, params[:journal_message]).message_id)
      return render_api_view(action: :create, status: :created)
    else
      return render_api_error(message: @issue.errors.full_messages)
    end
  rescue Exception => e
    render_api_error(message: "#{e.message} (#{e.backtrace.first})")
  end

  private

  def find_issue
    @issue = Issue.find(params[:journal_message] && params[:journal_message][:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_api_error(message: 'Issue not found', status: :not_found)
  end

  def find_project
    @project = @issue.project
    return render_api_error(message: 'Project not found', status: :not_found) unless @project
  end

  def validate_create_params
    return render_api_error(message: 'JournalMessage params cannot be blank') if params[:journal_message].blank?
    return render_api_error(message: 'Content data cannot be blank') if params[:journal_message][:content].blank?

    true
  end

  def render_api_error(opts)
    @error_messages = [opts[:message]]
    @status = opts[:status] || :unprocessable_entity
    respond_to do |format|
      format.any { head @status }
      format.api do
        render template: 'common/error_messages.api', status: @status, layout: opts[:layout]
      end
    end
    false
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
end

# {
#     "journal_message": {
#         "id": 51,
#         "from_address": "ar@kodep.ru",
#         "to_address": "reshetov_test@yandex.ru",
#         "cc_address": "_viruz_@mail.ru",
#         "bcc_address": "bcc@mail.ru",
#         "content": "Hello, I'm message text",
#         "message_date": "2019-05-29T13:21:58Z",
#         "message_id": "5cee8776327d8_4d922af2ed82386c68127@notebook.mail"
#     }
# }
