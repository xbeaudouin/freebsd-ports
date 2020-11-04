module RedmineHelpdesk
  module Patches
    module JournalPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development

          has_one :journal_message, :dependent => :destroy
          has_one :contact, :through => :journal_message

          attr_accessor :is_send_note
          attr_accessor :send_note_errors

          after_create :send_note
          after_create :update_helpdesk_ticket

          alias_method :css_classes_without_helpdesk, :css_classes
          alias_method :css_classes, :css_classes_with_helpdesk
        end
      end

      module InstanceMethods
        def is_incoming?
          journal_message && journal_message.is_incoming?
        end

        def is_sent?
          journal_message && !journal_message.is_incoming?
        end

        def message_author
          is_incoming? ? contact : user
        end

        def helpdesk_ticket
          journalized.respond_to?(:helpdesk_ticket) && journalized.helpdesk_ticket
        end

        def send_note
          require 'timeout'
          if issue.customer && is_send_note && notes
            journal_message = self.journal_message
            begin
              response_options = { :to_address => journal_message.to_address, :cc_address => journal_message.cc_address, :bcc_address => journal_message.bcc_address }
              Timeout::timeout(60) do
                if msg = HelpdeskMailer.issue_response(issue.customer, self, response_options)
                  msg_contact =
                  if msg.to_addrs.first
                    Contact.find_by_emails([msg.to_addrs.first]).first ||
                    HelpdeskMailSupport.create_contact_from_address(msg.to_addrs.first, msg.to_addrs.first, project)
                  else
                    issue.customer
                  end

                  journal_message.message_date = msg.date
                  journal_message.is_incoming = false
                  journal_message.message_id = msg.message_id.to_s.slice(0, 255)
                  journal_message.source = HelpdeskTicket::HELPDESK_EMAIL_SOURCE
                  journal_message.contact = msg_contact
                  journal_message.to_address = msg.to_addrs.first.to_s.slice(0, 255)
                  journal_message.cc_address = msg.cc.join(', ').to_s.slice(0, 255)
                  journal_message.bcc_address = msg.bcc.join(', ').to_s.slice(0, 255)
                  journal_message.save!
                end
              end
            rescue Exception => e
              self.send_note_errors = e.message
              HelpdeskLogger.try(:error, "Journal send error: #{[e.message, e.backtrace.first].join("\n")}")
            end
          end
        end

        def update_helpdesk_ticket
          return false if helpdesk_ticket.blank? || (helpdesk_ticket && helpdesk_ticket.ticket_date.blank?)
          helpdesk_ticket.save
        end

        def css_classes_with_helpdesk
          s = css_classes_without_helpdesk
          if journal_message
            s << ' has-journal-message'
            s << (journal_message.is_incoming? ? ' incoming' : ' outgoing')
          end
          s
        end
      end
    end
  end
end

unless Journal.included_modules.include?(RedmineHelpdesk::Patches::JournalPatch)
  Journal.send(:include, RedmineHelpdesk::Patches::JournalPatch)
end
