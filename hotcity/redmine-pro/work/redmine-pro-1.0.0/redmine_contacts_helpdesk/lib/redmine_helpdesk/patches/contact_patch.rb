module RedmineHelpdesk
  module Patches
    module ContactPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          has_many :journal_messages, :dependent => :destroy
          has_many :journals, :through => :journal_messages

          has_many :helpdesk_tickets, :dependent => :destroy
          has_many :tickets, :through => :helpdesk_tickets, :source => :issue # class_name => "Issue", :as  => :issue, :foreign_key => 'issue_id'

          def tickets_count
            tickets.count
          end
        end
      end

      module InstanceMethods
        def mail
          primary_email
        end

        def email_name
          [name, ' <', mail, '>'].join
        end

        def bracket_name
          return name if mail.blank?
          [name, ' (', mail, ')'].join
        end

        def all_tickets
          if is_company
            Issue.eager_load(:customer).where(:contacts => { :id => [id] | company_contacts.map(&:id) })
          else
            tickets
          end
        end

        def find_assigned_user(project, current_assigned_id)
          current_assigned_id ||= HelpdeskSettings['helpdesk_assigned_to', project]
          return Principal.find_by_id(current_assigned_id) unless RedmineHelpdesk.assign_contact_user?
          return assigned_to if assigned_to.present? && assigned_to.projects.include?(project)
          return contact_company.assigned_to if contact_company.present? && contact_company.assigned_to.present? &&
                                                contact_company.assigned_to.projects.include?(project)
          Principal.find_by_id(current_assigned_id)
        end
      end
    end
  end
end

unless Contact.included_modules.include?(RedmineHelpdesk::Patches::ContactPatch)
  Contact.send(:include, RedmineHelpdesk::Patches::ContactPatch)
end
