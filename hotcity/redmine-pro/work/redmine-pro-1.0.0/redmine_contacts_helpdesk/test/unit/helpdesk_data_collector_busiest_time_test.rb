require File.expand_path('../../test_helper', __FILE__)

class HelpdeskDataCollectorBusiestTimeTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :journals,
           :enabled_modules

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts, :contacts_projects])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:helpdesk_tickets, :journal_messages])

  def test_new_issues_count
    query = HelpdeskReportsBusiestTimeQuery.new(:name => 'name')
    query.filters = { 'report_date_period' => { :operator => 'm', :values => [''] } }

    this_month = (Date.today - Date.today.mday + 1).to_time..Time.now
    new_issues = query.issues.where(:created_on => this_month)

    assert_equal new_issues.count, HelpdeskDataCollectorBusiestTime.new(query).new_issues_count
  end

  def test_contacts_count
    query = HelpdeskReportsBusiestTimeQuery.new(:name => 'name')
    query.filters = { 'report_date_period' => { :operator => 'm', :values => [''] } }

    this_month = (Date.today - Date.today.mday + 1).to_time..Time.now
    issue_ids = query.issues.pluck(:id) | Issue.joins(:project).visible.where(:project_id => query.project).where(:created_on => this_month).pluck(:id)
    new_contacts = Contact.where(:id => Issue.where(:id => issue_ids).joins(:customer).map(&:customer).map(&:id).uniq).where(:created_on => this_month)

    assert_equal new_contacts.count, HelpdeskDataCollectorBusiestTime.new(query).contacts_count
  end

  def test_issues_count
    query = HelpdeskReportsBusiestTimeQuery.new(:name => 'name')
    query.filters = { 'report_date_period' => { :operator => 'm', :values => [''] } }

    this_month = (Date.today - Date.today.mday + 1).to_time..Time.now
    issue_ids = query.issues.pluck(:id) | Issue.joins(:project).visible.where(:project_id => query.project).where(:created_on => this_month).pluck(:id)
    total_incoming_count = JournalMessage.where(:is_incoming => true).where(:message_date => this_month).count + issue_ids.count

    assert_equal total_incoming_count, HelpdeskDataCollectorBusiestTime.new(query).issues_count
  end
end
