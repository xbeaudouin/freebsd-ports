module RedmineHelpdesk
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.send(:include, ActionView::Helpers::DateHelper)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          has_one :helpdesk_ticket, :dependent => :destroy
          has_one :customer, :through => :helpdesk_ticket

          scope :order_by_status, lambda { joins(:status).order("#{IssueStatus.table_name}.is_closed, #{IssueStatus.table_name}.id, #{Issue.table_name}.id DESC") }

          accepts_nested_attributes_for :helpdesk_ticket

          safe_attributes 'helpdesk_ticket_attributes',
            :if => lambda { |issue, user| user.allowed_to?(:edit_helpdesk_tickets, issue.project) }
        end
      end

      class HelpdeskTicketRelation < IssueRelation::Relations
        def to_s(*args)
          first.blank? || first.issue.blank? ? '' : first.issue.subject + first.issue.description.gsub("(\n|\r)", '') + ", #{l(:label_helpdesk_from)}: #{first.issue.customer.name}"
        end
      end

      module ClassMethods
        def load_helpdesk_data(issues, _user = User.current)
          if issues.any?
            helpdesk_tickets = HelpdeskTicket.where(:issue_id => issues.map(&:id))
            issues.each do |issue|
              issue.instance_variable_set '@helpdesk_ticket', (helpdesk_tickets.detect { |c| c.issue_id == issue.id } || nil)
            end
          end
        end
      end

      module InstanceMethods
        def journal_messages
          @journal_messages ||= JournalMessage.includes(:message_file, :contact => [:avatar, :projects]).
                                               where(:journal_id => journals.pluck(:id)).
                                               uniq.to_a
        end

        def is_ticket?
          helpdesk_ticket.present?
        end

        def last_message
          helpdesk_ticket && helpdesk_ticket.last_message ? helpdesk_ticket.last_message.content.truncate(250) : ''
        end

        def ticket_source
          helpdesk_ticket.ticket_source_name if helpdesk_ticket
        end

        def customer_company
          return nil unless customer
          customer.company
        end

        def last_message_date
          helpdesk_ticket.last_message_date if helpdesk_ticket
        end

        def ticket_reaction_time
          helpdesk_ticket && helpdesk_ticket.reaction_time ? distance_of_time_in_words(helpdesk_ticket.reaction_time) : ''
        end

        def ticket_first_response_time
          helpdesk_ticket && helpdesk_ticket.first_response_time ? distance_of_time_in_words(helpdesk_ticket.first_response_time) : ''
        end

        def ticket_resolve_time
          helpdesk_ticket && helpdesk_ticket.resolve_time ? distance_of_time_in_words(helpdesk_ticket.resolve_time) : ''
        end

        def vote
          helpdesk_ticket.present? && helpdesk_ticket.vote.present? ? HelpdeskTicket.vote_message(helpdesk_ticket.vote) : ''
        end

        def vote_comment
          helpdesk_ticket.present? && helpdesk_ticket.vote_comment.present? ? helpdesk_ticket.vote_comment.to_s : ''
        end

        def helpdesk_ticket_relation
          HelpdeskTicketRelation.new(self, [helpdesk_ticket])
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineHelpdesk::Patches::IssuePatch)
  Issue.send(:include, RedmineHelpdesk::Patches::IssuePatch)
end
