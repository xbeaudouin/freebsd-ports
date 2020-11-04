require File.expand_path('../../test_helper', __FILE__)

class IssueListReportTemplateTest < ActiveSupport::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers, :issue_categories, :attachments

  create_fixtures(Redmine::Plugin.find(:redmine_reporter).directory + '/test/fixtures/', [:report_templates])

  def test_should_generate_issue_list_report
    template = IssueListReportTemplate.find(3)
    issues = Issue.find(1, 2, 3, 4)
    reports = template.generate_reports(issues)
    assert reports.size == 1
    assert_equal template.name, reports.first.report_name
    assert_equal template.filename, reports.first.filename
    assert_equal '<h1>Issue List report example</h1><hr>4', reports.first.content
  end
end
