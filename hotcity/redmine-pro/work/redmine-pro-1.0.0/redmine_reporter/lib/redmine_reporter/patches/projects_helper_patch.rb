module RedmineReporter
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods

          alias_method :project_settings_tabs_without_reporter, :project_settings_tabs
          alias_method :project_settings_tabs, :project_settings_tabs_with_reporter
        end
      end

      module InstanceMethods
        def project_settings_tabs_with_reporter
          tabs = project_settings_tabs_without_reporter

          if User.current.allowed_to?(:manage_report_templates, @project)
            tabs << {
              name: 'report_templates',
              action: :manage_report_templates,
              partial: 'report_templates/index',
              label: :label_reporter_report_templates
            }
          end

          tabs
        end
      end

    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineReporter::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineReporter::Patches::ProjectsHelperPatch)
end
