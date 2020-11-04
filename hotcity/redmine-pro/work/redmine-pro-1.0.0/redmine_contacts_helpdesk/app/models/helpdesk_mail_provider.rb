class HelpdeskMailProvider
  attr_reader :mail_options, :options

  def initialize(mail_options = nil, options = {})
    @mail_options = mail_options
    @options = options
  end

  def self.receive(raw_message, options = {})
    new.receive(raw_message, options)
  end

  def receive(raw_message, options = {})
    mail_container = HelpdeskMailContainer.new(raw_message, options)
    mail_container.validate ? mail_container.dispatch : false
  rescue Exception => e
    Rails.logger.error("#{mail_container.try(:email).try(:message_id)}: receive error #{e.message}")
    Rails.logger.error(e.backtrace.first)
    false
  end

  def check
    raise 'Implement this method in inherited class'
  end
end
