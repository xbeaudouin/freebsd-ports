class HelpdeskMailContainer
  include HelpdeskMailerHelper

  class UnauthorizedAction < StandardError; end
  class MissingInformation < StandardError; end

  CONTAINER_ACCESSORS = [:email, :options, :logger, :contact, :target_project, :text_body, :from_addr, :from_user, :issue, :is_new_issue].freeze
  attr_accessor *CONTAINER_ACCESSORS

  def initialize(email_or_raw, options)
    email_or_raw.force_encoding('ASCII-8BIT') if email_or_raw.respond_to?(:force_encoding)
    @email = email_or_raw.is_a?(Mail) ? email_or_raw : Mail.new(email_or_raw)
    @options = options

    fill_accessors_from_options(options)

    @text_body ||= HelpdeskMailSupport.escaped_cleaned_up_text_body(email)
    @from_addr ||= message_sender(email)
    @from_user ||= User.find_by_mail(@from_addr) || User.anonymous
  end

  def validate
    return false if HelpdeskMailSupport.check_ignored_headers?(email, logger)
    return logged_error("#{email.message_id}: Email ignored because no FROM address found") if from_addr.blank?
    return logged_error("#{email.message_id}: Contacts and issues modules should be enable for #{target_project.name} project") if modules_disabled?
    return logged_error("#{email.message_id}: Ignoring email from Redmine emission address [#{from_addr}]") if sent_from_emission?
    return logged_error("#{email.message_id}: Email #{from_addr} ignored because in blacklist") if HelpdeskMailSupport.check_blacklist?(from_addr, target_project)
    return logged_error("#{email.message_id}: could not create/found contact for [#{@from_addr}]") unless contact
    # TODO: Add custom validate hook
    true
  end

  def dispatch
    # TODO: Before after dispatch hook
    m = email.subject && email.subject.match(HelpdeskMailSupport::ISSUE_REPLY_SUBJECT_RE)
    message_identifier = [email.in_reply_to, email.references].flatten.reject(&:blank?)
    journal_message = JournalMessage.where(message_id: message_identifier).first
    helpdesk_ticket = HelpdeskTicket.where(message_id: message_identifier).first
    if journal_message && journal_message.journal && journal_message.journal.issue
      HelpdeskMailRecipient::IssueReplyRecipient.new(self).receive(journal_message.journal.issue.id)
    elsif helpdesk_ticket && helpdesk_ticket.issue
      HelpdeskMailRecipient::IssueReplyRecipient.new(self).receive(helpdesk_ticket.issue.id)
    elsif m && Issue.exists?(m[1].to_i)
      HelpdeskMailRecipient::IssueReplyRecipient.new(self).receive(m[1].to_i)
    else
      @is_new_issue = true
      HelpdeskMailRecipient::IssueRecipient.new(self).receive
    end
    # TODO: Add after dispatch hook
  rescue MissingInformation => e
    logged_error("#{email.message_id}: missing information from #{from_user}: #{e.message}")
    logged_error(e.backtrace.first)
  rescue UnauthorizedAction => _e
    logged_error("#{email.message_id}: unauthorized attempt from #{from_user}")
  rescue Exception => e
    logged_error("#{email.message_id}: dispatch error #{e.message}")
    logged_error(e.backtrace.first)
  end

  def target_project
    return @target_project if @target_project
    @target_project ||= Project.where(identifier: get_keyword(:project) || get_keyword(:project_id)).first
    @target_project ||= Project.where(id: get_keyword(:project_id)).first
    raise MissingInformation.new('Unable to determine @target_project project') if @target_project.nil?
    @target_project
  end

  def get_keyword(attr, extra_options = {})
    @keywords ||= {}
    key_options = options.merge(extra_options)
    unless @keywords[attr]
      if attr_overridable?(attr, key_options)
        @keywords[attr] = HelpdeskMailSupport.extract_from_text!(text_body, attr, from_user, key_options[:format])
      end
      @keywords[attr] ||= key_options[:issue][attr] if key_options[:issue].present? && key_options[:issue][attr].present?
      @keywords[attr] ||= key_options[attr] if key_options[attr].present?
    end
    @keywords[attr]
  end

  def contact
    @contact ||= contact_from_email(email, target_project, logger)
  end

  private

  def fill_accessors_from_options(options)
    CONTAINER_ACCESSORS.each do |accessor|
      send("#{accessor}=", options[accessor]) if options[accessor]
    end
  end

  def modules_disabled?
    [:contacts, :issue_tracking].any? { |m| !target_project.module_enabled?(m) }
  end

  def sent_from_emission?
    from_addr.downcase == Setting.mail_from.to_s.strip.downcase
  end

  def with_ignored_header?
    HelpdeskMailSupport.ignored_headers(self, email)
  end

  def logged_error(message = nil)
    logger.error(message) if message
    false
  end

  def attr_overridable?(attr, attr_options)
    attr_options[:override] || (attr_options[:allow_override].present? && attr_options[:allow_override].include?(attr.to_s))
  end
end
