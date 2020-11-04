module RedmineHelpdesk
  module MailRules
    module Actions
      class CustomerTags < BaseAction
        def field
          'customer_tags'
        end

        def options
          {
            type: :contact_tags,
            name: l(:label_helpdesk_mail_rule_action_contact_tags)
          }
        end

        def apply(container, operator, value)
          return if container.nil? || container.contact.nil?
          container.contact.tag_list = splitted_values(value)
          container.contact.save
        end

        def values(rule_instance = nil)
          return [] unless rule_instance

          rule_instance.action_values_for(field)
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::CustomerTags)
