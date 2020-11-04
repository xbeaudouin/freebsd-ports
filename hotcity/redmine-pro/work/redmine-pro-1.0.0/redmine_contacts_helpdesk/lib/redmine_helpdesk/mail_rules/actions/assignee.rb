module RedmineHelpdesk
  module MailRules
    module Actions
      class Assignee < BaseAction
        def field
          'assignee'
        end

        def options
          {
            type: :assignee,
            name: l(:label_helpdesk_mail_rule_action_assignee)
          }
        end

        def values(rule_instance = nil)
          return [] unless rule_instance
          assignee_classes = ['User']
          assignee_classes << 'Group' if Setting.issue_group_assignment?
          ::Principal.where(type: assignee_classes)
                     .where(id: rule_instance.action_values_for(field)).map { |user| [user.name, user.id.to_s] }
        end

        def label_for(action_options)
          value = action_options[:values].join(',')
          ::Principal.where(id: value).first.try(:name)
        end

        def apply(container, operator, value)
          return if container.nil? || container.issue.nil?
          assigned_hash = Hash[value.map { |val| [val.to_i, 0] }].merge(Issue.open.where(assigned_to_id: value).group(:assigned_to_id).count(:id))
          assigned_id = assigned_hash.find { |id, val| val == assigned_hash.values.min }.first
          container.issue.update_column(:assigned_to_id, assigned_id)
          container.issue.send(:send_notification)
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::Assignee)
