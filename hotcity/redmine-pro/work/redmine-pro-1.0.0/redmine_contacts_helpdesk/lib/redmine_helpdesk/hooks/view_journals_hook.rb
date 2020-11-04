module RedmineHelpdesk
  module Hooks
    class ShowJournalContactHook < Redmine::Hook::ViewListener
      render_on :view_issues_history_journal_bottom, :partial => "journals/journal_contact" if Redmine::VERSION.to_s < '3.4'
    end
  end
end
