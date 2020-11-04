module RedmineReporter
  module Hooks
    class ViewsContextMenuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_context_menu_end, partial: 'context_menus/issues_reports'
      render_on :view_time_entries_context_menu_end, partial: 'context_menus/time_entries_reports'
    end
  end
end
