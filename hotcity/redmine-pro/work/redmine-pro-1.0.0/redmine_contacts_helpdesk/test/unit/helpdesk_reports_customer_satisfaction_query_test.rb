require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../../helpdesk_object_helpers', __FILE__)

include HelpdeskObjectHelpers

class HelpdeskReportsCustomerSatisfactionQueryTest < ActiveSupport::TestCase
  fixtures :projects,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :enumerations,
           :journals

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts, :contacts_projects])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', :helpdesk_tickets)

  def setup
    User.current = User.find(1)
  end

  def test_tickets_without_filters_include_ticket_from_this_month
    beginning_of_this_month = Date.today - (Date.today.mday - 1)
    ticket = ticket_with_last_agent_response_at(beginning_of_this_month)

    params = {}
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name').build_from_params(params)

    assert_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_without_filters_do_not_include_ticket_from_last_month
    end_of_last_month = Date.today - Date.today.mday
    ticket = ticket_with_last_agent_response_at(end_of_last_month)

    params = {}
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name').build_from_params(params)

    assert_not_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_with_report_date_period_filter
    date = Date.today
    ticket = ticket_with_last_agent_response_at(date + 1.minute)

    params = {
      :f => ['report_date_period'],
      :op => { 'report_date_period' => 't' },
      :v => { 'report_date_period' => [''] }
    }
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name').build_from_params(params)

    assert_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_with_report_date_period_filter_with_string_value
    date = Date.today
    ticket = ticket_with_last_agent_response_at(date + 1.minute)

    params = {
      :f => ['report_date_period'],
      :op => { 'report_date_period' => '=' },
      :v => { 'report_date_period' => [Date.today.to_s] }
    }
    query = HelpdeskReportsCustomerSatisfactionQuery.new(name: 'name').build_from_params(params)

    assert_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_with_customer_filter
    ticket = ticket_with_last_agent_response_at(Date.today)

    params = {
      :f => ['customer'],
      :op => { 'customer' => '=' },
      :v => { 'customer' => [ticket.contact_id] }
    }
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name').build_from_params(params)

    assert_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_with_source_filter
    ticket = ticket_with_last_agent_response_at(Date.today)

    params = {
      :f => ['source'],
      :op => { 'source' => '=' },
      :v => { 'source' => [ticket.source.to_s] }
    }
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name').build_from_params(params)

    assert_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_with_assigned_to_id_filter
    ticket = ticket_with_last_agent_response_at(Date.today)

    params = {
      :f => ['assigned_to_id'],
      :op => { 'assigned_to_id' => '=' },
      :v => { 'assigned_to_id' => [ticket.issue.assigned_to_id.to_s] }
    }
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name').build_from_params(params)

    assert_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_with_author_id_filter
    ticket = ticket_with_last_agent_response_at(Date.today)

    params = {
      :f => ['author_id'],
      :op => { 'author_id' => '=' },
      :v => { 'author_id' => [ticket.issue.author_id.to_s] }
    }
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name').build_from_params(params)

    assert_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_with_priority_id_filter
    ticket = ticket_with_last_agent_response_at(Date.today)

    params = {
      :f => ['priority_id'],
      :op => { 'priority_id' => '=' },
      :v => { 'priority_id' => [ticket.issue.priority_id.to_s] }
    }
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name').build_from_params(params)

    assert_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_with_tracker_id_filter
    ticket = ticket_with_last_agent_response_at(Date.today)

    params = {
      :f => ['tracker_id'],
      :op => { 'tracker_id' => '=' },
      :v => { 'tracker_id' => [ticket.issue.tracker_id.to_s] }
    }
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name').build_from_params(params)

    assert_include ticket.id, query.tickets.pluck('helpdesk_tickets.id')
  end

  def test_tickets_with_votes_count
    ticket_with_last_agent_response_at(Date.today, :vote => 2)
    ticket_with_last_agent_response_at(Date.today, :vote => 1)
    ticket_with_last_agent_response_at(Date.today, :vote => 0)

    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')

    assert_equal 3, query.tickets_with_votes_count
  end

  def test_tickets_with_votes_count_without_votes
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 0, query.tickets_with_votes_count
  end

  def test_not_good_count
    ticket_with_last_agent_response_at(Date.today, :vote => 0)
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 1, query.not_good_count
  end

  def test_not_good_count_without_votes
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 0, query.not_good_count
  end

  def test_just_ok_count
    ticket_with_last_agent_response_at(Date.today, :vote => 1)
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 1, query.just_ok_count
  end

  def test_just_ok_count_without_votes
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 0, query.just_ok_count
  end

  def test_awesome_count
    ticket_with_last_agent_response_at(Date.today, :vote => 2)
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 1, query.awesome_count
  end

  def test_awesome_count_without_votes
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 0, query.awesome_count
  end

  def test_not_good_percentage
    ticket_with_last_agent_response_at(Date.today, :vote => 0)
    ticket_with_last_agent_response_at(Date.today, :vote => 1)

    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')

    assert_equal 50.0, query.not_good_percentage
  end

  def test_not_good_percentage_without_votes
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 0, query.not_good_percentage
  end

  def test_just_ok_percentage
    ticket_with_last_agent_response_at(Date.today, :vote => 0)
    ticket_with_last_agent_response_at(Date.today, :vote => 1)
    ticket_with_last_agent_response_at(Date.today, :vote => 2)

    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 33.3, query.just_ok_percentage.round(1)
  end

  def test_just_ok_percentage_without_votes
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 0, query.just_ok_percentage
  end

  def test_awesome_percentage
    ticket_with_last_agent_response_at(Date.today, :vote => 2)
    ticket_with_last_agent_response_at(Date.today, :vote => 2)

    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')

    assert_equal 100.0, query.awesome_percentage
  end

  def test_awesome_percentage
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 0, query.awesome_percentage
  end

  def test_satisfaction_score
    ticket_with_last_agent_response_at(Date.today, :vote => 0)
    ticket_with_last_agent_response_at(Date.today, :vote => 2)
    ticket_with_last_agent_response_at(Date.today, :vote => 2)

    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')

    assert_equal query.awesome_percentage - query.not_good_percentage, query.satisfaction_score
  end

  def test_satisfaction_score_without_votes
    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')
    assert_equal 0, query.satisfaction_score
  end

  def test_total_votes
    ticket_with_last_agent_response_at(Date.today)
    ticket_with_last_agent_response_at(Date.today, :vote => 0)
    ticket_with_last_agent_response_at(Date.today, :vote => 1)

    query = HelpdeskReportsCustomerSatisfactionQuery.new(:name => 'name')

    assert_equal 66.7, query.total_votes.round(1)
  end

  private

  def ticket_with_last_agent_response_at(date, options = {})
    ticket = HelpdeskTicket.generate!(options)
    JournalMessage.generate!(
      :journal => Journal.generate!(:journalized => ticket.issue),
      :is_incoming => false,
      :message_date => date)

    %w(@responses @last_agent_response).each { |var| ticket.instance_variable_set(var, nil) }
    ticket.save
    ticket
  end
end
