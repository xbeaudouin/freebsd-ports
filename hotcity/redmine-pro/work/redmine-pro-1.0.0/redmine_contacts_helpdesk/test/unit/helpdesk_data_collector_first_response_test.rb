require File.expand_path('../../test_helper', __FILE__)

class HelpdeskDataCollectorFirstResponseTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :journals

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts, :contacts_projects])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', :helpdesk_tickets)

  def test_average_response_time
    responses = Issue.joins(:helpdesk_ticket).where('helpdesk_tickets.first_response_time > 0').pluck(:first_response_time).compact.sort
    middle = responses.count / 2
    average = responses.count.even? ? (responses[middle - 1] + responses[middle]) / 2 : responses[middle]

    assert_equal average.to_i, HelpdeskDataCollectorFirstResponse.new(query_mock).average_response_time
  end

  def test_average_close_time
    resolve_times = Issue.joins(:helpdesk_ticket, :status)
      .where('helpdesk_tickets.first_response_time > 0')
      .where("#{IssueStatus.table_name}.is_closed = ?", true).pluck(:resolve_time).compact.sort
    middle = resolve_times.count / 2
    average = resolve_times.count.even? ? (resolve_times[middle - 1] + resolve_times[middle]) / 2 : resolve_times[middle]

    assert_equal average.to_i, HelpdeskDataCollectorFirstResponse.new(query_mock).average_close_time
  end

  private

  def query_mock
    query = BasicObject.new

    def query.issues
      # In Rails < 4.0 Model.all returns an array rather than relation,
      # but the class under test will try to use 'joins' on it, so in order to
      # support Rails 3 the line below is written this way to return a relation
      # that includes all records.
      Issue.where('created_on IS NOT NULL')
    end

    def query.project; end

    def query.[](_key)
      { 'report_date_period' => { :operator => 'm', :values => [''] } }
    end

    query
  end
end
