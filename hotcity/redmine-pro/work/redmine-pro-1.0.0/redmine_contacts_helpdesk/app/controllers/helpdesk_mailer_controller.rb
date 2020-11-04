class HelpdeskMailerController < ActionController::Base
  unloadable
  before_action :check_credential

  # Submits an incoming email to ContactsMailer
  def index
    options = params.dup
    if options[:issue].present?
      project = Project.where(identifier: options[:issue][:project]).first
      options = HelpdeskMailSupport.issue_options(options, project.id) if project
    end
    email = options.delete(:email)
    if HelpdeskMailer.receive(email, options)
      head :created
    else
      head :unprocessable_entity
    end
  end

  def get_mail
    msg_count = 0
    errors = []
    projects = Project.active.has_module(:contacts_helpdesk)
    projects = projects.where(:id => params[:project_id]) if params[:project_id].present?
    projects.each do |project|
      begin
        msg_count += HelpdeskMailer.check_project(project.id)
      rescue Exception => e
        errors << e.message
      end
    end
    response_key = Redmine::VERSION.to_s >= '3.4' ? :plain : :text
    render :status => :ok, response_key => { :count => msg_count, :errors => errors }.to_json
  end

  private

  def check_credential
    User.current = nil
    unless Setting.mail_handler_api_enabled? && params[:key].to_s == Setting.mail_handler_api_key
      render plain: 'Access denied. Incoming emails WS is disabled or key is invalid.', status: 403
    end
  end
end
