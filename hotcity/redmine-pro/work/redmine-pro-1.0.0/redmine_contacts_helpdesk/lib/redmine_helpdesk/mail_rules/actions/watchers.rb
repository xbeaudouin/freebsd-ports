module RedmineHelpdesk
  module MailRules
    module Actions
      class Watchers < BaseAction
        def field
          'watchers'
        end

        def options
          {
            type: :assignee,
            name: l(:label_helpdesk_mail_rule_action_watchers)
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
          ::Principal.where(id: action_options[:values]).map(&:name).join(', ')
        end

        def apply(container, operator, value)
          return if container.nil? || container.issue.nil?

          container.issue.watcher_user_ids = value
          container.issue.send(:send_notification)
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::Watchers)
