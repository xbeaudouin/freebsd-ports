module RedmineHelpdesk
  module MailRules
    module Conditions
      class Tags < BaseCondition
        def field
          'issue_tags'
        end

        def options
          {
            type: :issue_tags,
            name: l(:label_helpdesk_mail_rule_condition_tags)
          }
        end

        def check(container, operator, values)
          issue = container.try(:issue)
          return false if issue.nil? || !issue.is_a?(Issue) || !issue.respond_to?(:tag_list)
          tags = issue.tag_list.sort
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

HelpdeskMailRule.add_condition(RedmineHelpdesk::MailRules::Conditions::Tags) if Redmine::Plugin.installed?(:redmineup_tags)
