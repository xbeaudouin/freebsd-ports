module RedmineHelpdesk
  module MailRules
    module Actions
      class Stop < BaseAction
        def field
          'stop'
        end

        def options
          {
            type: :stop,
            name: l(:label_helpdesk_mail_rule_action_stop)
          }
        end

        def apply(container, operator, value)
          false # Stop action returns false on apply
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::Stop)
