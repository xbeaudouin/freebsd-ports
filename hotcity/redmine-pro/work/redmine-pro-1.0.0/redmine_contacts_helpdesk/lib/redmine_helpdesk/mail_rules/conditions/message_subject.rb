module RedmineHelpdesk
  module MailRules
    module Conditions
      class MessageSubject < BaseCondition
        def field
          'message_subject'
        end

        def options
          {
            type: :string,
            name: l(:label_helpdesk_mail_rule_condition_message_subject)
          }
        end

        def check(container, operator, values)
          message_subject = container.try(:email).try(:subject)
          return false if message_subject.nil? || !message_subject.is_a?(String)
          value = values.join
          case operator
          when '='
            message_subject == value
          when '~'
            if value.include?(',')
              value.split(',').all? { |val| message_subject.downcase.include?(val.downcase) }
            elsif value.include?('|')
              value.split('|').any? { |val| message_subject.downcase.include?(val.downcase) }
            else
              message_subject.downcase.include?(value.downcase)
            end
          when '!'
            message_subject != value
          when '!~'
            !message_subject.downcase.include?(value.downcase)
          when '!*'
            message_subject.blank?
          when '*'
            message_subject.present?
          when '^'
            message_subject.match(/^#{value}/)
          when '$'
            message_subject.match(/#{value}$/)
          else
            false
          end
        end
      end
    end
  end
end

HelpdeskMailRule.add_condition(RedmineHelpdesk::MailRules::Conditions::MessageSubject)
