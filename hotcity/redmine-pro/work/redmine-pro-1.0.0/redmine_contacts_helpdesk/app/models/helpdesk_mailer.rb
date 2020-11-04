class HelpdeskMailer
  class << self
    def check_project(project_id, options = {})
      project = Project.where(id: project_id).first
      return 0 if project.nil? || HelpdeskSettings[:helpdesk_protocol, project.id].blank?
      mail_options, options = HelpdeskMailSupport.options_for_check(project_id, options)

      msg_count =
        case mail_options[:protocol]
        when 'pop3'
          HelpdeskMailProvider::Pop3.new(mail_options, with_logger(options)).check
        when 'imap'
          HelpdeskMailProvider::Imap.new(mail_options, with_logger(options)).check
        when 'api'
          HelpdeskMailProvider::Api.new(mail_options, with_logger(options)).check
        end

      HelpdeskTicket.autoclose(project)
      msg_count
    end

    def receive(raw_message, options = {})
      HelpdeskMailProvider.receive(raw_message, with_logger(options))
    end

    def initial_message(contact, issue, options = {})
      with_performed_delivery do
        HelpdeskMailMessenger::InitialMessage.prepare_email(contact, issue, with_logger(options)).deliver
      end
    end

    def auto_answer(contact, issue, options = {})
      with_performed_delivery do
        HelpdeskMailMessenger::AutoAnswerMessage.prepare_email(contact, issue, with_logger(options)).deliver
      end
    end

    def issue_response(contact, journal, options = {})
      with_performed_delivery do
        HelpdeskMailMessenger::IssueResponseMessage.prepare_email(contact, journal, with_logger(options)).deliver
      end
    end

    def autoclose_message(contact, issue, options = {})
      with_performed_delivery do
        HelpdeskMailMessenger::AutocloseMessage.prepare_email(contact, issue, with_logger(options)).deliver
      end
    end

    private

    def logger
      HelpdeskLogger
    end

    def with_logger(options)
      options.merge(logger: logger)
    end

    def with_performed_delivery
      perform_delivery_state = ActionMailer::Base.perform_deliveries
      ActionMailer::Base.perform_deliveries = true
      yield
    ensure
      ActionMailer::Base.perform_deliveries = perform_delivery_state
    end
  end
end
