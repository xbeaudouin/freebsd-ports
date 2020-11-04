module RedmineHelpdesk
  module MailRules
    module Actions
      class Project < BaseAction
        def field
          'project'
        end

        def options
          {
            type: :list,
            multi: true,
            name: l(:label_helpdesk_mail_rule_action_project)
          }
        end

        def values(_rule_instance = nil)
          ::Project.visible.has_module('contacts_helpdesk').map { |project| [project.name, project.id.to_s] }
        end

        def label_for(action_options)
          value = action_options[:values].join(',')
          values.detect { |val| val.last == value }.try(:first)
        end

        def apply(container, operator, value)
          project = ::Project.has_module('contacts_helpdesk').where(id: value.join.to_i).first
          return if container.nil? || container.issue.nil? || project.nil?
          container.issue.update_column(:project_id, project.id)
        end
      end
    end
  end
end

HelpdeskMailRule.add_action(RedmineHelpdesk::MailRules::Actions::Project)
