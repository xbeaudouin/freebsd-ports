require File.expand_path('../../test_helper', __FILE__)

class HelpdeskTicketsControllerTest < ActionController::TestCase

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
    RedmineHelpdesk::TestCase.prepare
  end

  def test_should_get_edit
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :edit, :issue_id => 1, :id => 1
    assert_response 200
  end

  def test_should_create_ticket
    @request.session[:user_id] = 1
    compatible_request :put, :update, :helpdesk_ticket => { :contact_id => 1, :source => '0', :ticket_date => '2013-01-01' },
                                      :time => { :hour => 21, :minute => 12 },
                                      :issue_id => 1,
                                      :id => 1
    assert_redirected_to :controller => 'issues', :action => 'show', :id => '1'
    assert_not_nil HelpdeskTicket.find_by_from_address(Contact.find(1).primary_email)
  end

  def test_should_destroy
    @request.session[:user_id] = 1
    compatible_request :delete, :destroy, id: HelpdeskTicket.find(3).issue_id
    assert_response :redirect
    assert_nil HelpdeskTicket.find_by_id(3)
  end

  def test_should_update_cutomer_profile
    @request.session[:user_id] = 1
    ticket = HelpdeskTicket.find(2)
    compatible_request :put, :update, helpdesk_ticket: { contact_id: 1, source: '2', ticket_date: '2013-01-01' },
                                      issue_id: ticket.issue_id,
                                      id: ticket.issue_id
    assert_redirected_to controller: 'issues', action: 'show', id: ticket.issue_id
    ticket.reload
    assert_equal Contact.find(1).primary_email, ticket.from_address
    assert_equal 2, ticket.issue_id
    assert_equal 2, ticket.source
  end

  def test_should_update_cutomer_profile_with_non_primary_email
    @request.session[:user_id] = 1
    ticket = HelpdeskTicket.find(2)
    contact = Contact.find(2)
    compatible_request :put, :update, helpdesk_ticket: { from_address: contact.emails.last, source: '2', ticket_date: '2013-01-01' },
                                      issue_id: ticket.issue_id,
                                      id: ticket.issue_id
    assert_redirected_to controller: 'issues', action: 'show', id: ticket.issue_id
    ticket.reload
    assert_equal contact.emails.last, ticket.from_address
    assert_equal 2, ticket.issue_id
    assert_equal 2, ticket.source
  end
end
