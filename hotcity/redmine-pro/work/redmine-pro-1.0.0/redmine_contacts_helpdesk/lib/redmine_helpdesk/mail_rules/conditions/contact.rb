module RedmineHelpdesk
  module MailRules
    module Conditions
      class Contact < BaseCondition
        def field
          'contact'
        end

        def options
          {
            type: :contact,
            name: l(:label_helpdesk_mail_rule_condition_contact)
          }
        end

        def label_for(condition_options)
          ::Contact.visible.where(id: condition_options[:values]).map(&:name).join(', ')
        end

        def values(rule_instance = nil)
          return [] unless rule_instance
          return [] if rule_instance.condition_values_for(field).empty?
          ::Contact.visible.where(id: rule_instance.condition_values_for(field)).map { |r| [r.name, r.id.to_s] }
        end

        def check(container, operator, values)
          contact = container.try(:contact)
          return false if contact.nil? || !contact.is_a?(::Contact)
          value_contacts = ::Contact.where(id: values.sort)
          case operator
          when '='
            value_contacts.include?(contact)
          when '!'
            !value_contacts.include?(contact)
          when '!*'
            false
          when '*'
            true
          else
            false
          end
        end
      end
    end
  end
end

HelpdeskMailRule.add_condition(RedmineHelpdesk::MailRules::Conditions::Contact)
