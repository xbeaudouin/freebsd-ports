module RedmineHelpdesk
  module MailRules
    module Actions
      class IssueTracker < BaseAction
        def field
          'issue_tracker'
        end

        def options
          {
            type: :list,
            name: l(:label_helpdesk_mail_rule_action_issue_tracker)
          }
        end

        def values(_rule_instance = nil)
          ::Tracker.all.map { |status| [status.name, status.id.to_s] }
        end

        def label_for(action_options)
          value = action_options[:values].join(',')
          values.detect { |val| val.last == value }.try(:first)
        end

        def apply(container, operator, value)
          tracker = ::Tracker.where(id: value.join.to_i).first
          return if container.nil? || container.issue.nil? || tracker.nil?
          container.issue.update_column(:tracker_id, tracker.id)
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::IssueTracker)
