requires_redmine_crm :version_or_higher => '0.0.43' rescue raise "\n\033[31mRedmine requires newer redmine_crm gem version.\nPlease update with 'bundle update redmine_crm'.\033[0m"

require 'redmine'
require 'redmine_reporter'

REPORTER_VERSION_NUMBER = '1.0.3'

Redmine::Plugin.register :redmine_reporter do
  name 'Redmine Reporter plugin (PRO version)'
  author 'RedmineUP'
  description 'Printable reports generation for Redmine issues'
  version REPORTER_VERSION_NUMBER
  url 'https://www.redmineup.com/pages/plugins/reporter'
  author_url 'mailto:support@redmineup.com'

  requires_redmine :version_or_higher => '2.6'

  settings default: {}, partial: 'settings/reporter/index'

  project_module :issue_tracking do
    permission :manage_report_templates, { report_templates: [:new, :create, :edit, :update, :destroy, :preview, :export, :new_import, :import] }
    permission :generate_issue_reports, { issues_report_templates: [:new, :create, :autocomplete, :attach]}
    permission :view_issue_reports, { issues_report_templates: [:preview]}
    permission :send_issues, { issue_mails: [:new, :send_mail, :preview] }
  end

  project_module :time_tracking do
    permission :generate_time_entries_reports, { time_entries_reports: [:new, :create, :autocomplete]}
    permission :view_time_entries_reports, { time_entries_reports: [:preview]}
  end
end
