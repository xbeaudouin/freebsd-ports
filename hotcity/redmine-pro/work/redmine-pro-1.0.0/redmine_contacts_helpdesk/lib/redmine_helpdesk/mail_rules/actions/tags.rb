module RedmineHelpdesk
  module MailRules
    module Actions
      class Tags < BaseAction
        def field
          'tags'
        end

        def options
          {
            type: :issue_tags,
            name: l(:label_helpdesk_mail_rule_action_tags)
          }
        end

        def apply(container, operator, value)
          return if container.nil? || container.issue.nil?
          container.issue.tag_list = splitted_values(value)
          container.issue.save(validate: false)
        end

        def values(rule_instance = nil)
          return [] unless rule_instance

          rule_instance.action_values_for(field)
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::Tags) if Redmine::Plugin.installed?(:redmineup_tags)
