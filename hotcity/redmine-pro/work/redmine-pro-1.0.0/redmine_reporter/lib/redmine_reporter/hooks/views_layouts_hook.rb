module RedmineReporter
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_body_bottom, partial: 'timelog/query_reports_link'

      def view_layouts_base_html_head(context = {})
        stylesheet_link_tag(:redmine_reporter, plugin: 'redmine_reporter') +
          javascript_include_tag(:redmine_reporter, plugin: 'redmine_reporter')
      end
    end
  end
end
