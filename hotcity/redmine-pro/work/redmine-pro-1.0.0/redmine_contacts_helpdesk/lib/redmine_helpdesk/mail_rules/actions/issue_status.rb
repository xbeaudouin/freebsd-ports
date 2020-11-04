module RedmineHelpdesk
  module MailRules
    module Actions
      class IssueStatus < BaseAction
        def field
          'issue_status'
        end

        def options
          {
            type: :list,
            name: l(:label_helpdesk_mail_rule_action_issue_status)
          }
        end

        def values(_rule_instance = nil)
          ::IssueStatus.all.map { |status| [status.name, status.id.to_s] }
        end

        def label_for(action_options)
          value = action_options[:values].join(',')
          values.detect { |val| val.last == value }.try(:first)
        end

        def apply(container, operator, value)
          status = ::IssueStatus.where(id: value.join.to_i).first
          return if container.nil? || container.issue.nil? || status.nil?
          container.issue.update_column(:status_id, status.id)
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::IssueStatus)
