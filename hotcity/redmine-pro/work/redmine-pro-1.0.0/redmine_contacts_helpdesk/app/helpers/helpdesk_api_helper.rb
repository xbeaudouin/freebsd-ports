module HelpdeskApiHelper
  def render_api_helpdesk_ticket(helpdesk_ticket, api)
    api.id helpdesk_ticket.issue.id
    api.from_address helpdesk_ticket.from_address
    api.to_address helpdesk_ticket.to_address || ''
    api.cc_address helpdesk_ticket.cc_address
    api.message_id helpdesk_ticket.message_id
    api.ticket_date format_date(helpdesk_ticket.ticket_date)
    api.content helpdesk_ticket.issue.description
    api.source helpdesk_ticket.ticket_source_name
    api.is_incoming helpdesk_ticket.is_incoming
    api.reaction_time helpdesk_ticket.reaction_time || ''
    api.first_response_time helpdesk_ticket.first_response_time || ''
    api.resolve_time helpdesk_ticket.resolve_time || ''
    api.last_agent_response_at format_date(helpdesk_ticket.last_agent_response_at) || ''
    api.last_customer_response_at format_date(helpdesk_ticket.last_customer_response_at) || ''
    api.contact(id: helpdesk_ticket.contact_id, name: helpdesk_ticket.customer.name) if helpdesk_ticket.customer.present?
    api.vote helpdesk_ticket.vote
    api.vote_comment helpdesk_ticket.vote_comment
    api.message_file do
      render_api_attachment(helpdesk_ticket.message_file, api)
    end if helpdesk_ticket.message_file.present?
    api.array :journal_messages do
      helpdesk_ticket.issue.journal_messages.each do |journal_message|
        api.journal_message do
          api.contact(id: journal_message.contact_id, name: journal_message.contact.name) if journal_message.contact.present?
          api.from_address journal_message.from_address
          api.to_address journal_message.to_address
          api.cc_address journal_message.cc_address
          api.bcc_address journal_message.bcc_address
          api.message_date format_date(journal_message.message_date)
          api.is_incoming journal_message.is_incoming
          api.content journal_message.content
          api.message_id journal_message.message_id
          api.journal_id journal_message.journal_id
          api.viewed_on journal_message.viewed_on
          api.message_file do
            render_api_attachment(journal_message.message_file, api)
          end if journal_message.message_file.present?
        end
      end
    end if include_in_api_response?('journal_messages')
    api.array :journals do
      helpdesk_ticket.journals.each do |journal|
        api.journal do
          api.id journal.id
          api.notes journal.notes
          api.created_on journal.created_on
        end
      end
    end if include_in_api_response?('journals')
  end

  def render_api_journal_message(journal_message, api)
    api.id journal_message.journal_id
    api.from_address journal_message.from_address
    api.to_address journal_message.to_address
    api.cc_address journal_message.cc_address
    api.bcc_address journal_message.bcc_address
    api.content journal_message.journal.notes
    api.message_date format_date(journal_message.message_date)
    api.message_id journal_message.message_id
  end
end
