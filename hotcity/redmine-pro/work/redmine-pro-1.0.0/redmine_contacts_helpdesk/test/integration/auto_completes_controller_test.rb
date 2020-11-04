require File.expand_path('../../test_helper', __FILE__)

class RedmineHelpdesk::AutoCompletesControllerTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
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
                                                                                                                             :canned_responses,
                                                                                                                             :helpdesk_tickets])

  def setup
    RedmineHelpdesk::TestCase.prepare
    @project = Project.find(1)
  end

  def test_sohuld_returns_contacts_without_email
    contact_without_email = Contact.create(projects: [@project], first_name: 'No email')
    log_user("admin", "admin")
    compatible_request :get, "/auto_completes/contacts?project_id=#{@project.identifier}&q=No"
    assert_response :success
    assert_include "No email", response.body
  end
end
