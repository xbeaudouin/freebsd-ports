module RedmineHelpdesk
  module MailRules
    module Actions
      class DueDate < BaseAction
        def field
          'due_date'
        end

        def options
          {
            type: :date_with_labels,
            name: l(:label_helpdesk_mail_rule_action_issue_due_date)
          }
        end

        def values(_rule_instance = nil)
          return []
        end

        def label_for(action_options)
          value = action_options[:values].join(',')
          case action_options[:operator]
          when '='
            value
          when 't'
            l(:label_today)
          when 'nd'
            l(:label_tomorrow)
          when 'da'
            l(:label_helpdesk_days_after_full, days: value)
          end
        end

        def apply(container, operator, value)
          value = value.join
          due_date =
            case operator
            when '='
              Date.parse(value)
            when 't'
              Date.today
            when 'nd'
              Date.tomorrow
            when 'da'
              Date.today + value.to_i.days
            end
          container.issue.update_column(:due_date, due_date)
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::DueDate)
