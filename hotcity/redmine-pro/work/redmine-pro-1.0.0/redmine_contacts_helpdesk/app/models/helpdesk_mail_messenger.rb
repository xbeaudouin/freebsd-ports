class HelpdeskMailMessenger < MailHandler
  include HelpdeskMailerHelper
  helper :helpdesk_mailer

  class MissingInformation < StandardError; end

  attr_reader :logger, :contact, :object, :options, :email

  def prepare_email(contact, object, options = {})
    @logger = options[:logger]
    @contact = contact
    @object = object
    @options = (options.respond_to?(:to_unsafe_hash) ? options.to_unsafe_hash : options).with_indifferent_access
    @email = build_email
    @container = HelpdeskMailContainer.new(email, logger: logger, contact: contact, issue: issue)

    set_delivery_options

    HelpdeskMailRule.apply_rules(:outgoing, @container)
    logger.try(:info, "##{object.id}: Sending #{self.class.name} to #{to_address}")
    email
  end

  def self.default_url_options
    { host: Setting.host_name, protocol: Setting.protocol }
  end

  def build_email
    raise 'Method should be implemented in inherited classes'
  end

  def project
    raise 'Method should be implemented in inherited classes'
  end

  private

  def set_delivery_options
    return if HelpdeskSettings['helpdesk_smtp_use_default_settings', project].to_i == 0

    email.delivery_method(:smtp)
    email.delivery_method.settings.merge!(address: HelpdeskSettings['helpdesk_smtp_server', project],
                                          port: HelpdeskSettings['helpdesk_smtp_port', project] || 25,
                                          authentication: HelpdeskSettings['helpdesk_smtp_authentication', project] || 'plain',
                                          user_name: HelpdeskSettings['helpdesk_smtp_username', project],
                                          password: HelpdeskSettings['helpdesk_smtp_password', project],
                                          domain: HelpdeskSettings['helpdesk_smtp_domain', project],
                                          enable_starttls_auto: true,
                                          ssl: HelpdeskSettings['helpdesk_smtp_ssl', project].to_i > 0 &&
                                               HelpdeskSettings['helpdesk_smtp_tls', project].to_i == 0)
  end

  def validate; end

  def from_address(journal_user = nil)
    mail_from ||= options[:from_address]
    mail_from ||= HelpdeskSettings['helpdesk_answer_from', project].blank? ? Setting.mail_from : HelpdeskSettings['helpdesk_answer_from', project]
    logger.try(:error, "##{object.id}: From address couldn't be blank") if mail_from.blank?
    HelpdeskMailSupport.apply_from_macro(mail_from.to_s, journal_user)
  end

  def to_address
    options[:to_address] || contact.primary_email
  end
end
