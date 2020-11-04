module RedmineHelpdesk
  module MailRules
    module Conditions
      class MessageBody < BaseCondition
        def field
          'message_body'
        end

        def options
          {
            type: :string,
            name: l(:label_helpdesk_mail_rule_condition_message_body)
          }
        end

        def check(container, operator, values)
          message_body = container.try(:text_body)
          return false if message_body.nil? || !message_body.is_a?(String)
          value = values.join
          case operator
          when '='
            message_body == value
          when '~'
            if value.include?(',')
              value.split(',').all? { |val| message_body.downcase.include?(val.downcase) }
            elsif value.include?('|')
              value.split('|').any? { |val| message_body.downcase.include?(val.downcase) }
            else
              message_body.downcase.include?(value.downcase)
            end
          when '!'
            message_body != value
          when '!~'
            !message_body.downcase.include?(value.downcase)
          when '!*'
            message_body.blank?
          when '*'
            message_body.present?
          when '^'
            message_body.match(/^#{value}/)
          when '$'
            message_body.match(/#{value}$/)
          else
            false
          end
        end
      end
    end
  end
end

HelpdeskMailRule.add_condition(RedmineHelpdesk::MailRules::Conditions::MessageBody)
