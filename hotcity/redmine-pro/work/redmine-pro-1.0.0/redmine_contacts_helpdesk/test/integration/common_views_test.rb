require File.expand_path('../../test_helper', __FILE__)

class RedmineHelpdesk::CommonViewsTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
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
  end

  test "View project settings" do
    log_user("admin", "admin")
    compatible_request :get, "/projects/ecookbook/settings"
    assert_response :success
  end

  test "View helpdesk plugin settings" do
    log_user("admin", "admin")
    compatible_request :get, "/settings/plugin/redmine_contacts_helpdesk"
    assert_response :success
  end

  test "View helpdesk plugin settings with hidden tab" do
    log_user("admin", "admin")
    compatible_request :get, "/settings/plugin/redmine_contacts_helpdesk?hidden=true"
    assert_response :success
  end

  test "View issue" do
    log_user("admin", "admin")
    compatible_request :get, "/issues/1"
    assert_response :success
  end

  test "View issues" do
    log_user("admin", "admin")
    compatible_request :get, "/issues"
    assert_response :success
  end

  test "View project issues" do
    log_user("admin", "admin")
    compatible_request :get, "/projects/ecookbook/issues"
    assert_response :success
  end

  test "Can view helpdesk reports with permissons" do
    log_user("admin", "admin")
    get "/projects/ecookbook"
    assert response.body.match /Helpdesk reports/
  end

  test "Can not view helpdesk reports without permissons" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook"
    assert_no_match %r{Helpdesk reports}, response.body
  end
end
