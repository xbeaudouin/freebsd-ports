module RedmineHelpdesk
  module MailRules
    module Conditions
      class ContactTags < BaseCondition
        def field
          'contact_tags'
        end

        def options
          {
            type: :contact_tags,
            name: l(:label_helpdesk_mail_rule_condition_contact_tags)
          }
        end

        def check(container, operator, values)
          contact = container.try(:contact)
          return false if contact.nil? || !contact.is_a?(::Contact)
          tags = contact.tag_list.sort
          values = splitted_values(values).sort
          case operator
          when '='
            tags == values
          when '~'
            (values - tags).empty?
          when '!', '!~'
            (tags - values) == tags
          when '!*'
            tags.empty?
          when '*'
            tags.present?
          else
            false
          end
        end

        def values(rule_instance = nil)
          return [] unless rule_instance

          rule_instance.condition_values_for(field)
        end
      end
    end
  end
end

HelpdeskMailRule.add_condition(RedmineHelpdesk::MailRules::Conditions::ContactTags)
