require File.expand_path('../../../test_helper', __FILE__)
# require File.dirname(__FILE__) + '/../../../../../test/test_helper'

class Redmine::ApiTest::HelpdeskTicketsTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
  include RedmineHelpdesk::TestHelper

  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages,
                                                                                                                             :helpdesk_tickets])

  def setup
    Setting.rest_api_enabled = '1'
    RedmineHelpdesk::TestCase.prepare
    @project = Project.find(1)
    @support_tracker = Tracker.where(name: 'Support request').first
    @assigned_status = IssueStatus.where(name: 'Assigned').first
    @high_priority = IssuePriority.where(name: 'High').first
  end

  def test_create_ticket_returns_validation_errors
    params_with_validation_errors.each do |test_case|
      Redmine::ApiTest::Base.should_allow_api_authentication(:post, '/helpdesk_tickets.json',
                                                             test_case[:params],
                                                             success_code: :created) if ActiveRecord::VERSION::MAJOR < 4
      compatible_api_request :post, '/helpdesk_tickets.json', test_case[:params], credentials('admin')

      assert_response test_case[:code]

      if Redmine::VERSION.to_s >= '2.7'
        assert_equal JSON.parse(@response.body), { 'errors' => [test_case[:error]] }
      else
        assert JSON.parse(@response.body)['errors'].any?
      end
    end
  end

  def test_post_create_ticket
    ActionMailer::Base.deliveries.clear
    Redmine::ApiTest::Base.should_allow_api_authentication(:post, '/helpdesk_tickets.json',
                                                           helpdesk_ticket_params,
                                                           success_code: :created) if ActiveRecord::VERSION::MAJOR < 4

    assert_difference('Issue.count') do
      compatible_api_request :post, '/helpdesk_tickets.json', helpdesk_ticket_params, credentials('admin')
    end

    issue = Issue.order('id DESC').first
    assert_equal @project.id, issue.project_id
    assert_equal @support_tracker.id, issue.tracker_id
    assert_equal @assigned_status.id, issue.status_id
    assert_equal 'Ticket body', issue.description
    assert_equal 'API test', issue.subject

    contact = issue.customer
    assert_equal 'Firstname', contact.first_name
    assert_equal 'contact@email.com', contact.email

    assert_response :created
    assert_equal 'application/json', @response.content_type
    assert_equal helpdesk_ticket_response(issue), JSON.parse(@response.body)
    assert_match /You have received this notification because you have/, ActionMailer::Base.deliveries.first.text_part.body.to_s
  end

  def test_post_create_ticket_with_initial_send_as
    ActionMailer::Base.deliveries.clear
    initial_message_params = helpdesk_ticket_params
    initial_message_params[:helpdesk_ticket][:send_as] = 'initial_message'
    Redmine::ApiTest::Base.should_allow_api_authentication(:post, '/helpdesk_tickets.json',
                                                           initial_message_params,
                                                           success_code: :created) if ActiveRecord::VERSION::MAJOR < 4
    assert_difference('Issue.count') do
      compatible_api_request :post, '/helpdesk_tickets.json', initial_message_params, credentials('admin')
    end

    assert_response :created
    helpdesk_ticket = HelpdeskTicket.order('id DESC').first
    assert_equal false, helpdesk_ticket.is_incoming
    assert_match /Ticket body/, ActionMailer::Base.deliveries.last.text_part.body.to_s
  end

  def test_post_create_ticket_with_auto_answer_send_as
    ActionMailer::Base.deliveries.clear
    initial_message_params = helpdesk_ticket_params
    initial_message_params[:helpdesk_ticket][:send_as] = 'auto_answer'
    Redmine::ApiTest::Base.should_allow_api_authentication(:post, '/helpdesk_tickets.json',
                                                           initial_message_params,
                                                           success_code: :created) if ActiveRecord::VERSION::MAJOR < 4
    assert_difference('Issue.count') do
      compatible_api_request :post, '/helpdesk_tickets.json', initial_message_params, credentials('admin')
    end

    assert_response :created
    helpdesk_ticket = HelpdeskTicket.order('id DESC').first
    assert_equal true, helpdesk_ticket.is_incoming
    assert_match /We hereby confirm that we have received your message/, ActionMailer::Base.deliveries.last.text_part.body.to_s
  end

  def test_put_update_ticket
    ActionMailer::Base.deliveries.clear
    helpdesk_ticket = HelpdeskTicket.order('id ASC').first
    Redmine::ApiTest::Base.should_allow_api_authentication(:put, "/helpdesk_tickets/#{helpdesk_ticket.issue.id}.json",
                                                           helpdesk_ticket_update,
                                                           success_code: :created) if ActiveRecord::VERSION::MAJOR < 4
    compatible_api_request :put, "/helpdesk_tickets/#{helpdesk_ticket.issue.id}.json", helpdesk_ticket_update, credentials('admin')

    assert_response :ok
    helpdesk_ticket.reload

    assert_equal false, helpdesk_ticket.is_incoming
    assert_equal 1, helpdesk_ticket.vote
    assert_equal 'Vote comment', helpdesk_ticket.vote_comment
    assert Contact.where(email: 'new_from@email.com').first
  end

  def test_delete_destroy_ticket
    ActionMailer::Base.deliveries.clear
    issue = HelpdeskTicket.find(1).issue
    Redmine::ApiTest::Base.should_allow_api_authentication(:delete, "/helpdesk_tickets/#{issue.id}.json") if ActiveRecord::VERSION::MAJOR < 4
    compatible_api_request :delete, "/helpdesk_tickets/#{issue.id}.json", {}, credentials('admin')

    assert_response :no_content
    issue.reload
    assert_nil issue.helpdesk_ticket
  end

  test "GET /helpdesk_tickets/:id.xml" do
    compatible_api_request :get, '/helpdesk_tickets/1.xml', {}, credentials('admin')
    assert_select 'helpdesk_ticket' do
      assert_select 'id', text: '1'
      assert_select 'from_address', text: 'test1@mail.address'
    end
    assert_nothing_raised do
      Hash.from_xml(response.body).to_xml
    end
  end

  test "GET /helpdesk_tickets/:id.xml with journal_messages" do
    compatible_api_request :get, '/helpdesk_tickets/1.xml', {include: 'journal_messages'}, credentials('admin')
    assert_select 'helpdesk_ticket' do
      assert_select 'id', text: '1'
      assert_select 'from_address', text: 'test1@mail.address'
      assert_select 'helpdesk_ticket journal_messages[type=array]' do
        assert_select 'contact[id="1"]'
        assert_select 'journal_id', text: '1'
      end
    end
    assert_nothing_raised do
      Hash.from_xml(response.body).to_xml
    end
  end

  private

  def params_with_validation_errors
    [
      { params: {}, code: 404, error: 'Project not found' }, # empty params
      { params: { helpdesk_ticket: {} }, code: 404, error: 'Project not found' },
      { params: { helpdesk_ticket: { issue: {} } }, code: 404, error: 'Project not found' },
      { params: { helpdesk_ticket: { issue: { project_id: 'not_found' } } }, code: 404, error: 'Project not found' },
      { params: { helpdesk_ticket: { issue: { project_id: @project.identifier } } },
        code: 422, error: 'Contact params cannot be blank' },
      { params: { helpdesk_ticket: { issue: { project_id: @project.identifier },
                                     contact: {} } },
        code: 422, error: 'Contact params cannot be blank' },
      { params: { helpdesk_ticket: { issue: { project_id: @project.identifier },
                                     contact: { first_name: 'Firstname' } } },
        code: 422, error: 'Contact should have email address' },
      { params: { helpdesk_ticket: { issue: { project_id: @project.identifier },
                                     contact: { email: 'email@email.com' } } },
        code: 422, error: ['Subject cannot be blank', 'First name cannot be blank'] },
      { params: { helpdesk_ticket: { issue: { project_id: @project.identifier, subject: 'Test subject' },
                                     contact: { email: 'email@email.com' } } },
        code: 422, error: ['First name cannot be blank'] },
      { params: { helpdesk_ticket: { issue: { project_id: @project.identifier },
                                     contact: { email: 'email@email.com', first_name: 'Firstname' } } },
        code: 422, error: ['Subject cannot be blank'] }
    ]
  end

  def helpdesk_ticket_params
    {
      helpdesk_ticket: {
        source: 'conversation',
        cc_address: 'cc@email.com',
        message_id: 'message-id-string',
        vote: 1,
        vote_comment: 'Vote text',
        issue: {
          project_id: @project.identifier,
          tracker_id: @support_tracker.id,
          description: 'Ticket body',
          subject: 'API test',
          status_id: @assigned_status.id,
          priority_id: @high_priority.id
        },
        contact: {
          email: 'contact@email.com',
          first_name: 'Firstname',
          last_name: 'Lastname',
          middle_name: 'Middlename',
          tag_list: 'issue,api'
        }
      }
    }
  end

  def helpdesk_ticket_response(issue)
    {
      'helpdesk_ticket' =>
        {
          'id' => issue.id,
          'from_address' => 'contact@email.com',
          'to_address' => '',
          'cc_address' => 'cc@email.com',
          'message_id' => 'message-id-string',
          'ticket_date' => ::I18n.l(issue.helpdesk_ticket.ticket_date.to_date),
          'content' => 'Ticket body',
          'source' => 'Conversation',
          'is_incoming' => true,
          'reaction_time' => '',
          'first_response_time' => '',
          'resolve_time' => '',
          'last_agent_response_at' => '',
          'last_customer_response_at' => '',
          'contact' => {
            'id' => issue.customer.id,
            'name' => 'Firstname Lastname'
          },
          'vote' => 1,
          'vote_comment' => 'Vote text'
        }
    }
  end

  def helpdesk_ticket_update
    {
      helpdesk_ticket: {
        from_address: 'new_from@email.com',
        cc_address: 'new_cc@email.com',
        vote: 1,
        vote_comment: 'Vote comment',
        is_incoming: false
      }
    }
  end
end
