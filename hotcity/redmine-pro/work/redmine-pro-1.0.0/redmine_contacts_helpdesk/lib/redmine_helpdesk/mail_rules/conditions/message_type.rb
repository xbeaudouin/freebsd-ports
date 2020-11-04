module RedmineHelpdesk
  module MailRules
    module Conditions
      class MessageType < BaseCondition
        def field
          'message_type'
        end

        def options
          {
            type: :list,
            name: l(:label_helpdesk_mail_rule_condition_message_type)
          }
        end

        def values(_rule_instance = nil)
          [
            [l(:label_helpdesk_mail_rule_condition_message_type_new), '0'],
            [l(:label_helpdesk_mail_rule_condition_message_type_response), '1']
          ]
        end

        def label_for(condition_options)
          value = condition_options[:values].join(',')
          values.detect { |val| val.last == value }.try(:first)
        end

        def check(container, operator, values)
          is_new = container.is_new_issue
          value = values.join.to_i
          case operator
          when '='
            value == 0 ? is_new : !is_new
          when '~'
            value == 0 ? !is_new : is_new
          end
        end
      end
    end
  end
end

HelpdeskMailRule.add_condition(RedmineHelpdesk::MailRules::Conditions::MessageType)
