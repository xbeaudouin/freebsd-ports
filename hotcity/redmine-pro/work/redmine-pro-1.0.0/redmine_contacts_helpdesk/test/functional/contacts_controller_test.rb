require File.expand_path('../../test_helper', __FILE__)

# Re-raise errors caught by the controller.
# class HelpdeskMailerController; def rescue_action(e) raise e end; end

class ContactsControllerTest < ActionController::TestCase
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

  RedmineHelpdesk::TestCase.create_fixtures(
    Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/',
    [
      :contacts,
      :contacts_projects,
      :deals,
      :notes,
      :tags,
      :taggings,
      :queries
    ]
  )

  RedmineHelpdesk::TestCase.create_fixtures(
    Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/',
    [:journal_messages, :helpdesk_tickets]
  )

  include RedmineHelpdesk::TestHelper

  def setup
    RedmineHelpdesk::TestCase.prepare
    ActionMailer::Base.deliveries.clear
    User.current = nil
  end

  def test_contacts_with_closed_tickets
    @request.session[:user_id] = 1
    compatible_request :get,
                       :index,
                       'f' => ['open_tickets', ''],
                       'op' => { 'open_tickets' => '=' },
                       'v' => { 'open_tickets' => ['0'] }
    assert_response :success
    assert !contacts_in_list.include?(Contact.find(1))
  end

  def test_contacts_with_open_tickets
    @request.session[:user_id] = 1
    compatible_request :get,
                       :index,
                       'f' => ['open_tickets', ''],
                       'op' => { 'open_tickets' => '=' },
                       'v' => { 'open_tickets' => ['1'] }
    assert_response :success
    assert contacts_in_list.include?(Contact.find(1))
  end

  def test_contacts_with_number_of_tickets
    @request.session[:user_id] = 1
    compatible_request :get,
                       :index,
                       'f' => ['number_of_tickets', ''],
                       'op' => { 'number_of_tickets' => '=' },
                       'v' => { 'number_of_tickets' => ['1'] }
    assert_response :success
    contacts_in_list.each do |contact|
      assert contact.helpdesk_tickets.count == 1
    end
  end

  def test_contacts_with_zero_tickets
    @request.session[:user_id] = 1
    compatible_request :get,
                       :index,
                       'f' => ['number_of_tickets', ''],
                       'op' => { 'number_of_tickets' => '=' },
                       'v' => { 'number_of_tickets' => ['0'] }
    assert_response :success
    contacts_in_list.each do |contact|
      assert contact.helpdesk_tickets.count == 0
    end
  end

  def test_contacts_without_tickets
    @request.session[:user_id] = 1
    compatible_request :get,
                       :index,
                       'f' => ['number_of_tickets', ''],
                       'op' => { 'number_of_tickets' => '!*' },
                       'v' => { 'number_of_tickets' => [''] }
    assert_response :success
    contacts_in_list.each do |contact|
      assert contact.helpdesk_tickets.count == 0
    end
  end

  def test_contacts_with_any_tickets
    @request.session[:user_id] = 1
    compatible_request :get,
                       :index,
                       'f' => ['number_of_tickets', ''],
                       'op' => { 'number_of_tickets' => '*' },
                       'v' => { 'number_of_tickets' => [''] }
    assert_response :success
    contacts_in_list.each do |contact|
      assert contact.helpdesk_tickets.count > 0
    end
  end

  def test_contacts_with_x_or_more_tickets
    @request.session[:user_id] = 1
    compatible_request :get,
                       :index,
                       'f' => ['number_of_tickets', ''],
                       'op' => { 'number_of_tickets' => '>=' },
                       'v' => { 'number_of_tickets' => ['2'] }
    assert_response :success
    contacts_in_list.each do |contact|
      assert contact.helpdesk_tickets.count >= 2
    end
  end

  def test_contacts_with_x_or_less_tickets
    @request.session[:user_id] = 1
    compatible_request :get,
                       :index,
                       'f' => ['number_of_tickets', ''],
                       'op' => { 'number_of_tickets' => '<=' },
                       'v' => { 'number_of_tickets' => ['2'] }
    assert_response :success
    contacts_in_list.each do |contact|
      assert contact.helpdesk_tickets.count <= 2
    end
  end

  def test_show_where_helpdesk_ticket_has_no_description
    @request.session[:user_id] = 1
    contact = Contact.find(1)
    Issue.update(contact.tickets.first.id, :description => nil)

    compatible_request :get, :show, :id => contact, :tab => 'helpdesk'
    assert_response :success
    assert_select '#helpdesk_tickets', true
  end

  def test_ticket_count_column_not_rendered_when_not_selected
    @request.session[:user_id] = 1
    compatible_request :get, :index, :contacts_list_style => 'list'

    assert_response :success
    assert_select 'th', :text => 'Tickets count', :count => 0
  end if CONTACTS_VERSION_TYPE.include?('PRO')

  def test_ticket_count_column_rendered
    @request.session[:user_id] = 1
    compatible_request :get, :index, :contacts_list_style => 'list', :c => ['tickets_count']

    assert_response :success
    assert_select 'th', 'Tickets count'
  end if CONTACTS_VERSION_TYPE.include?('PRO')

  def test_ticket_count_column_not_rendered_when_not_table_style
    @request.session[:user_id] = 1
    compatible_request :get, :index, :c => ['tickets_count']

    assert_response :success
    assert_select 'th', :text => 'Tickets count', :count => 0
  end if CONTACTS_VERSION_TYPE.include?('PRO')
end
