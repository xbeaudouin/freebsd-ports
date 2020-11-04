module RedmineReporter
  module Hooks
    class ViewIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_index_bottom, partial: 'issues/query_reports_link'
      render_on :view_issues_show_details_bottom, partial: 'issues/show_details_bottom'
    end
  end
end
