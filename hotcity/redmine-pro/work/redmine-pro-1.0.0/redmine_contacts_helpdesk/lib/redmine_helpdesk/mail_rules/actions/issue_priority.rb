module RedmineHelpdesk
  module MailRules
    module Actions
      class IssuePriority < BaseAction
        def field
          'priority'
        end

        def options
          {
            type: :list,
            name: l(:label_helpdesk_mail_rule_action_issue_priority)
          }
        end

        def values(_rule_instance = nil)
          ::IssuePriority.all.map { |priority| [priority.name, priority.id.to_s] }
        end

        def label_for(action_options)
          value = action_options[:values].join(',')
          values.detect { |val| val.last == value }.try(:first)
        end

        def apply(container, operator, value)
          priority = ::IssuePriority.where(id: value.join.to_i).first
          return if container.nil? || container.issue.nil? || priority.nil?
          container.issue.update_column(:priority_id, priority.id)
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::IssuePriority)
