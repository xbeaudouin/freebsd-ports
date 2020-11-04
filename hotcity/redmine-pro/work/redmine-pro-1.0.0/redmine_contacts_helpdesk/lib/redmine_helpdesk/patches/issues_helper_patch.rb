module RedmineHelpdesk
  module Patches
    module IssuesHelperPatch
      def self.included(base)
        base.class_eval do
          unloadable
          alias_method :issue_history_tabs_without_helpdesk, :issue_history_tabs
          alias_method :issue_history_tabs, :issue_history_tabs_with_helpdesk
        end
      end

      def issue_history_tabs_with_helpdesk
        tabs = issue_history_tabs_without_helpdesk
        if @issue.journal_messages.any?
          tabs << {:name => 'helpdesk_conversation', :label => :label_helpdesk_journal_conversation, :onclick => 'showHelpdeskHistory("helpdesk_conversation", this.href)'}
        end
        tabs
      end
    end
  end
end

if Redmine::VERSION.to_s > '4.1' && !IssuesHelper.included_modules.include?(RedmineHelpdesk::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineHelpdesk::Patches::IssuesHelperPatch)
end
