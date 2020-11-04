require File.expand_path('../../test_helper', __FILE__)

class IssueQueryPatchTest < ActiveSupport::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts, :contacts_projects])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages, :helpdesk_tickets])

  def test_company_filter_with_equals_operator
    company_name = 'Domoway'
    issue_ids = Issue.joins(:helpdesk_ticket => [:customer]).where("LOWER(#{Contact.table_name}.company) = LOWER('#{company_name}')").pluck(:id)
    query = IssueQuery.new(:name => 'name', :filters => { 'customer_company' => { :operator => '=', :values => [company_name] } })

    assert_equal issue_ids.sort, query.issues.map(&:id).sort
  end

  def test_company_filter_with_contains_operator
    company_name = 'omoway'
    issue_ids = Issue.joins(:helpdesk_ticket => [:customer]).where("LOWER(#{Contact.table_name}.company) LIKE LOWER('%#{company_name}%')").pluck(:id)
    query = IssueQuery.new(:name => 'name', :filters => { 'customer_company' => { :operator => '~', :values => [company_name] } })

    assert_equal issue_ids.sort, query.issues.map(&:id).sort
  end

  def test_company_filter_with_any_operator
    issue_ids = Issue.joins(:helpdesk_ticket => [:customer]).where("COALESCE(#{Contact.table_name}.company, '') <> ''").pluck(:id)
    query = IssueQuery.new(:name => 'name', :filters => { 'customer_company' => { :operator => '*', :values => [''] } })

    assert_equal issue_ids.sort, query.issues.map(&:id).sort
  end

  def test_company_filter_with_none_operator
    issue_ids = Issue.joins(:helpdesk_ticket => [:customer]).where("COALESCE(LOWER(#{Contact.table_name}.company), '') = ''").pluck(:id)
    query = IssueQuery.new(:name => 'name', :filters => { 'customer_company' => { :operator => '!*', :values => [''] } })

    assert_equal issue_ids.sort, query.issues.map(&:id).sort
  end
end
