module RedmineHelpdesk
  module MailRules
    module Conditions
      class FromAddress < BaseCondition
        def field
          'from_address'
        end

        def options
          {
            type: :string,
            name: l(:label_helpdesk_mail_rule_condition_from_address)
          }
        end

        def check(container, operator, values)
          from_addr = container.try(:from_addr)
          return false if from_addr.nil? || !from_addr.is_a?(String)
          value = values.join
          case operator
          when '='
            from_addr == value
          when '~'
            if value.include?(',')
              value.split(',').all? { |val| from_addr.downcase.include?(val.downcase) }
            elsif value.include?('|')
              value.split('|').any? { |val| from_addr.downcase.include?(val.downcase) }
            else
              from_addr.downcase.include?(value.downcase)
            end
          when '!'
            from_addr != value
          when '!~'
            !from_addr.downcase.include?(value.downcase)
          when '!*'
            from_addr.blank?
          when '*'
            from_addr.present?
          when '^'
            from_addr.match(/^#{value}/)
          when '$'
            from_addr.match(/#{value}$/)
          else
            false
          end
        end
      end
    end
  end
end

HelpdeskMailRule.add_condition(RedmineHelpdesk::MailRules::Conditions::FromAddress)
