require File.expand_path('../../test_helper', __FILE__)

class IssueReportTemplateTest < ActiveSupport::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers, :issue_categories, :attachments

  create_fixtures(Redmine::Plugin.find(:redmine_reporter).directory + '/test/fixtures/', [:report_templates])

  def setup
    @template = IssueReportTemplate.find(1)
  end

  def test_should_generate_issue_report
    issue = Issue.find(1)
    reports = @template.generate_reports([issue])
    assert reports.size == 1
    check_report reports.first, issue
  end

  def test_should_generate_issue_reports
    issues = Issue.find(1, 2, 3, 4)
    reports = @template.generate_reports(issues)
    assert reports.size == issues.size
    reports.each_with_index { |report, index| check_report(report, issues[index]) }
  end

  private

  def check_report(report, issue)
    expected_report = Report.new(
      "#{@template.name} (##{issue.id})",
      @template.filename('.pdf', issue: issue),
      "<h1>Issue report example</h1><hr>#{issue.subject}",
      @template.public_link_params(issue)
    )
    assert_equal expected_report.report_name, report.report_name
    assert_equal expected_report.filename, report.filename
    assert_equal expected_report.content, report.content
  end
end
