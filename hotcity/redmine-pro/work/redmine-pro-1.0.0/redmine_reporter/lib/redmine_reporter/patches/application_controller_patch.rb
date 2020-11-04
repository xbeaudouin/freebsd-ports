module RedmineReporter
  module Patches
    module ApplicationControllerPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods
        end
      end

      module InstanceMethods
        def find_report_templates
          @report_templates = []
          if params[:report_template] && params[:report_template][:ids].present?
            @report_templates = ReportTemplate.issue_templates.find(params[:report_template][:ids])
          end

          if @report_templates.blank?
            flash[:error] = l(:label_reporter_templates_no_selected)
            redirect_to_referer_or { render html: l(:label_reporter_templates_no_selected), status: 200, layout: true }
          end
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        def apply_layout(content, layout)
          if Rails::VERSION::MAJOR < 4
            render_to_string(text: content, layout: layout)
          else
            render_to_string(html: content, layout: layout)
          end
        end

        def apply_layout!(content, layout)
          content.replace apply_layout(content, layout)
        end
      end
    end
  end
end

unless ApplicationController.included_modules.include?(RedmineReporter::Patches::ApplicationControllerPatch)
  ApplicationController.send(:include, RedmineReporter::Patches::ApplicationControllerPatch)
end
