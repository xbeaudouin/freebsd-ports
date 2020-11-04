module RedmineReporter
  module Patches
    module ApplicationHelperPatch
      def self.included(base)
        base.class_eval do
          def report_templates_check_box_tags(name, templates)
            return '' if templates.blank?
            s = ''
            templates.each do |template|
              s << "<label>#{check_box_tag name, template.id, false, id: nil} #{h template.name}</label>\n"
            end
            s << javascript_tag('addReportTemplatesCheckboxesListener();')
            s.html_safe
          end
        end
      end
    end
  end
end

unless ApplicationHelper.included_modules.include?(RedmineReporter::Patches::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedmineReporter::Patches::ApplicationHelperPatch)
end
