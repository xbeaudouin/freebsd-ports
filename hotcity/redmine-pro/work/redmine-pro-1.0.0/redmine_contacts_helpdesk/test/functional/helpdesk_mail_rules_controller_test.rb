require File.expand_path('../../test_helper', __FILE__)

class HelpdeskMailRulesControllerTest < ActionController::TestCase

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
                                                                                                                             :helpdesk_tickets,
                                                                                                                             :helpdesk_mail_rules])

  def setup
    RedmineHelpdesk::TestCase.prepare

    @request.session[:user_id] = 1
  end

  def test_should_get_new
    compatible_request :get, :new
    assert_select '#content h2', 'Email rule'
    assert_response 200
  end

  def test_should_create_rule
    compatible_request :post, :create, mail_type: '0', f: ['message_body', ''],
                                       op: { message_body: '~' },
                                       v: { message_body: ['Test'], priority: ['5'] },
                                       a: ['priority', '']
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => 'redmine_contacts_helpdesk', tab: 'email_rules'
    created_rule = HelpdeskMailRule.last
    assert_equal '{"message_body"=>{:operator=>"~", :values=>["Test"]}}', created_rule.conditions.to_s
    assert_equal '{"priority"=>{:operator=>nil, :values=>["5"]}}', created_rule.actions.to_s
  end

  def test_should_update_rule
    rule = HelpdeskMailRule.find(1)
    compatible_request :put, :update, id: 1, mail_type: '0', f: ['message_subject', ''],
                                        op: { message_subject: '~' },
                                        v: { message_subject: ['Hello'], priority: ['1'] },
                                        a: ['priority', '']
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => 'redmine_contacts_helpdesk', tab: 'email_rules'
    assert_equal '{"message_subject"=>{:operator=>"~", :values=>["Hello"]}}', rule.reload.conditions.to_s
    assert_equal '{"priority"=>{:operator=>nil, :values=>["1"]}}', rule.reload.actions.to_s
  end

  def test_should_destroy
    assert_not_nil HelpdeskMailRule.where(id: 1).first
    compatible_request :delete, :destroy, :id => 1
    assert_response :redirect
    assert_nil HelpdeskMailRule.where(id: 1).first
  end
end
