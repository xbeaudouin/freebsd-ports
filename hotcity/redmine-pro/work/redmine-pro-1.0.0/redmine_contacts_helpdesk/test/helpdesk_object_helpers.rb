module HelpdeskObjectHelpers
  include ObjectHelpers

  def HelpdeskTicket.generate!(attributes = {})
    ticket = HelpdeskTicket.new(attributes)
    ticket.issue ||= Issue.generate!
    ticket.customer ||= Contact.find(1)
    ticket.ticket_date ||= Time.now
    ticket.save!
    ticket
  end

  def JournalMessage.generate!(attributes = {})
    message = JournalMessage.new(attributes)
    message.contact ||= Contact.find(1)
    message.journal ||= Journal.find(1)
    message.message_date ||= Time.now
    message.save!
    message
  end
end
