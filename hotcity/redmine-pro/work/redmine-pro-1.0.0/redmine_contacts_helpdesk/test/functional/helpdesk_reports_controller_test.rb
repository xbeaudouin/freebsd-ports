require File.expand_path('../../test_helper', __FILE__)

class HelpdeskReportsControllerTest < ActionController::TestCase

  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :journals

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', :contacts)

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages, :helpdesk_tickets])

  def setup
    RedmineHelpdesk::TestCase.prepare
    User.current = nil
  end

  def test_show_first_response_time_report
    HelpdeskDataCollectorFirstResponse.any_instance.stubs(:issues).returns(Issue.where(:id => 1))

    @request.session[:user_id] = 1
    compatible_request :get, :show, :project_id => 1, :report => 'first_response_time', :set_filter => '1', :f => ['message_date', ''], :op => { 'message_date' => 't' }

    assert_response :success
    assert_select '#content h2', 'First response time'
    assert_select '.nodata', false
  ensure
    HelpdeskDataCollectorFirstResponse.any_instance.unstub(:issues)
  end

  def test_show_first_response_time_report_without_params
    HelpdeskDataCollectorFirstResponse.any_instance.stubs(:issues).returns(Issue.where(:id => 1))

    @request.session[:user_id] = 1
    compatible_request :get, :show, :project_id => 1, :report => 'first_response_time', :set_filter => '1', :f => ['']

    assert_response :success
    assert_select '#content h2', 'First response time'
    assert_select '.nodata', false
  ensure
    HelpdeskDataCollectorFirstResponse.any_instance.unstub(:issues)
  end

  def test_show_first_response_time_report_with_no_data
    HelpdeskDataCollectorFirstResponse.any_instance.stubs(:issues).returns(Issue.where(:id => 0))

    @request.session[:user_id] = 1
    compatible_request :get, :show, :project_id => 1, :report => 'first_response_time', :set_filter => '1', :f => ['message_date', ''], :op => { 'message_date' => 'lm' }

    assert_response :success
    assert_select '#content h2', 'First response time'
    assert_select '.nodata', 'No data to display'
  ensure
    HelpdeskDataCollectorFirstResponse.any_instance.unstub(:issues)
  end

  def test_show_first_response_time_report_without_project
    HelpdeskDataCollectorFirstResponse.any_instance.stubs(:issues).returns(Issue.where(:id => 1))

    @request.session[:user_id] = 1
    compatible_request :get, :show, :report => 'first_response_time'

    assert_response :success
    assert_select '#content h2', 'First response time'
    assert_select '.nodata', false
  ensure
    HelpdeskDataCollectorFirstResponse.any_instance.unstub(:issues)
  end

  def test_show_busiest_time_of_day
    HelpdeskDataCollectorBusiestTime.any_instance.stubs(:issues_count).returns(1)

    @request.session[:user_id] = 1
    compatible_request :get, :show, :project_id => 1, :report => 'busiest_time_of_day', :set_filter => '1', :f => ['message_date', ''], :op => { 'message_date' => 'y' }

    assert_response :success
    assert_select '#content h2', 'Busiest time of day'
    assert_select '.nodata', false
  ensure
    HelpdeskDataCollectorBusiestTime.any_instance.unstub(:issues_count)
  end

  def test_show_busiest_time_of_day_with_no_data
    HelpdeskDataCollectorBusiestTime.any_instance.stubs(:issues_count).returns(0)

    @request.session[:user_id] = 1
    compatible_request :get, :show, :project_id => 1, :report => 'busiest_time_of_day', :set_filter => '1', :f => ['message_date', ''], :op => { 'message_date' => 't' }

    assert_response :success
    assert_select '#content h2', 'Busiest time of day'
    assert_select '.nodata', 'No data to display'
  ensure
    HelpdeskDataCollectorBusiestTime.any_instance.unstub(:issues_count)
  end

  def test_show_busiest_time_of_day_without_project
    HelpdeskDataCollectorBusiestTime.any_instance.stubs(:issues_count).returns(1)

    @request.session[:user_id] = 1
    compatible_request :get, :show, :report => 'busiest_time_of_day'

    assert_response :success
    assert_select '#content h2', 'Busiest time of day'
    assert_select '.nodata', false
  ensure
    HelpdeskDataCollectorBusiestTime.any_instance.unstub(:issues_count)
  end

  def test_show_customer_satisfaction_report
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.stubs(:tickets_with_votes_count).returns(4)
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.stubs(:awesome_percentage).returns(50.0)
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.stubs(:not_good_percentage).returns(25.0)

    @request.session[:user_id] = 1
    compatible_request :get, :show, :project_id => 1, :report => 'customer_satisfaction'

    assert_response :success
    assert_select '#content h2', 'Customer satisfaction'
    assert_select '.nodata', false
    assert_select '#satisfaction-score', '25%'
  ensure
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.unstub(:tickets_with_votes_count)
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.unstub(:awesome_percentage)
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.unstub(:not_good_percentage)
  end

  def test_show_customer_satisfaction_report_with_no_data
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.stubs(:tickets_with_votes_count).returns(0)

    @request.session[:user_id] = 1
    compatible_request :get, :show, :project_id => 1, :report => 'customer_satisfaction'

    assert_response :success
    assert_select '#content h2', 'Customer satisfaction'
    assert_select '.nodata', 'No data to display'
  ensure
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.unstub(:tickets_with_votes_count)
  end

  def test_show_customer_satisfaction_report_without_project
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.stubs(:tickets_with_votes_count).returns(1)

    @request.session[:user_id] = 1
    compatible_request :get, :show, :report => 'customer_satisfaction'

    assert_response :success
    assert_select '#content h2', 'Customer satisfaction'
    assert_select '.nodata', false
  ensure
    HelpdeskReportsCustomerSatisfactionQuery.any_instance.unstub(:tickets_with_votes_count)
  end
end
