require File.expand_path('../../test_helper', __FILE__)

class TimeEntriesReportTemplateTest < ActiveSupport::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :time_entries

  create_fixtures(Redmine::Plugin.find(:redmine_reporter).directory + '/test/fixtures/', [:report_templates])

  def test_should_generate_time_entries_report
    template = TimeEntriesReportTemplate.find(6)
    time_entries = TimeEntry.find(1, 2, 3, 4)
    reports = template.generate_reports(time_entries)
    assert reports.size == 1
    assert_equal template.name, reports.first.report_name
    assert_equal template.filename, reports.first.filename
    assert_equal '<div>Time entries size: 4</div> <div>Issues size: 2</div>', reports.first.content
  end
end
