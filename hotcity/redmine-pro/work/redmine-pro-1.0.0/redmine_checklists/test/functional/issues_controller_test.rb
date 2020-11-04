# encoding: utf-8
#
# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

# Re-raise errors caught by the controller.
# class HelpdeskMailerController; def rescue_action(e) raise e end; end

class IssuesControllerTest < ActionController::TestCase
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

  RedmineChecklists::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_checklists).directory + '/test/fixtures/', [:checklists])

  def setup
    @request.session[:user_id] = 1
    RedmineChecklists::TestCase.prepare
  end
  def test_show_index_with_checklists_status_filter
    compatible_request :get, :index, project_id: 1, set_filter: '1', f: ['checklists_status', ''], op: { checklists_status: '=' }, v: { checklists_status: ['1'] }
    assert_response :success
    assert_equal issues_in_list.map(&:id), [2, 1]

    compatible_request :get, :index, project_id: 1, set_filter: '1', f: ['checklists_status', ''], op: { checklists_status: '=' }, v: { checklists_status: ['0'] }
    assert_response :success
    assert_equal issues_in_list.map(&:id), [1]
  end

  def test_show_index_with_checklists_item_filter
    compatible_request :get, :index, project_id: 1, set_filter: '1', f: ['checklists_item', ''], op: { checklists_item: '~' }, v: { checklists_item: ['todo'] }
    assert_response :success
    assert_equal issues_in_list.map(&:id), [2, 1]

    compatible_request :get, :index, project_id: 1, set_filter: '1', f: ['checklists_item', ''], op: { checklists_item: '~' }, v: { checklists_item: ['Third'] }
    assert_response :success
    assert_equal issues_in_list.map(&:id), [2]

    compatible_request :get, :index, project_id: 1, set_filter: '1', f: ['checklists_item', ''], op: { checklists_item: '~' }, v: { checklists_item: ['section'] }
    assert_response :success
    assert_equal issues_in_list.map(&:id), [2]

    compatible_request :get, :index, project_id: 1, set_filter: '1', f: ['checklists_item', ''], op: { checklists_item: '!*' }
    assert_response :success
    assert_equal issues_in_list.map(&:id).include?(1), false
    assert_equal issues_in_list.map(&:id).include?(2), false
  end

  def test_new_issue_without_project
    compatible_request :get, :new
    assert_response :success
  end if Redmine::VERSION.to_s > '3.0'

  def test_get_show_issue
    issue = Issue.find(1)
    assert_not_nil issue.checklists.first
    compatible_request(:get, :show, :id => 1)
    assert_response :success
    assert_select "ul#checklist_items li#checklist_item_1", /First todo/
    assert_select "ul#checklist_items li#checklist_item_1 input[checked=?]", "checked", { :count => 0 }
    assert_select "ul#checklist_items li#checklist_item_2 input[checked=?]", "checked"
  end

  def test_get_edit_issue
    compatible_request :get, :edit, :id => 1
    assert_response :success
  end

  def test_get_copy_issue
    compatible_request :get, :new, :project_id => 1, :copy_from => 1
    assert_response :success
    assert_select "span#checklist_form_items span.checklist-subject", { :count => 3 }
    assert_select "span#checklist_form_items span.checklist-edit input[value=?]", "First todo"
  end

  def test_put_update_form
    parameters = {:tracker_id => 2,
                  :checklists_attributes => {
                    "0" => {"is_done"=>"0", "subject"=>"FirstChecklist"},
                    "1" => {"is_done"=>"0", "subject"=>"Second"}}}

    @request.session[:user_id] = 1
    issue = Issue.find(1)
    if Redmine::VERSION.to_s > '2.3' && Redmine::VERSION.to_s < '3.0'
      compatible_xhr_request :put, :update_form, :issue => parameters, :project_id => issue.project
    else
      compatible_xhr_request :put, :new, :issue => parameters, :project_id => issue.project
    end
    assert_response :success
    assert_equal 'text/javascript', response.content_type
    assert_match 'FirstChecklist', response.body
  end
  def test_update_sends_email
    Setting[:plugin_redmine_checklists] = { :save_log => 1, :issue_done_ratio => 0 }
    parameters = { :checklists_attributes => { '0' => { 'is_done' => '0', 'subject' => 'Third' },
                                               '1' => { 'is_done' => '1', 'subject' => 'Fourth' },
                                               '2' => { 'id' => 2, '_destroy' => '1', 'subject' => 'Second todo' }
                    } }

    @request.session[:user_id] = 1
    issue = Issue.find(1)
    EmailAddress.create!(:user_id => 2, :address => 'test@example.com') if Redmine::VERSION.to_s >= '3.0'

    compatible_xhr_request :put, :update, :issue => parameters, :project_id => issue.project, :id => issue.to_param
    assert ActionMailer::Base.deliveries.last
    email = ActionMailer::Base.deliveries.last
    assert_include 'Checklist item [ ] Third added', email.text_part.body.to_s
    assert_include 'Checklist item [x] Fourth added', email.text_part.body.to_s
    assert_include 'Checklist item deleted (Second todo)', email.text_part.body.to_s
  end

  def test_update_send_notification_email
    old_events = Setting.notified_events
    Setting.notified_events = ['checklist_updated']
    Setting[:plugin_redmine_checklists] = { :save_log => 1, :issue_done_ratio => 0 }
    parameters = { 'checklists_attributes' => { '0' => { 'is_done' => '0', 'subject' => 'Third' },
                                                '1' => { 'is_done' => '1', 'subject' => 'Fourth' },
                                                '2' => { 'id' => '2', '_destroy' => '1', 'subject' => 'Second todo' } } }
    @request.session[:user_id] = 1
    issue = Issue.find(1)
    EmailAddress.create!(:user_id => 2, :address => 'test@example.com', :is_default => true) if Redmine::VERSION.to_s >= '3.0'

    compatible_xhr_request :put, :update, :issue => parameters, :project_id => issue.project, :id => issue.to_param
    assert ActionMailer::Base.deliveries.last
    email = ActionMailer::Base.deliveries.last
    assert_include 'Checklist item [ ] Third added', email.text_part.body.to_s
  ensure
    Setting.notified_events = old_events
  end

  def test_update_status_with_checklist_destroy
    issue = Issue.find(1)
    initial_status = issue.status_id
    closed_status = IssueStatus.where(:is_closed => true).first
    with_checklists_settings('block_issue_closing' => '1') do
      parameters = { :status_id => closed_status.id,
                     :checklists_attributes => { '2' => { 'is_done' => '0', 'subject' => 'New Section', 'is_section' => 'true' },
                                                 '0' => { 'id' => 1, 'is_done' => '1', 'subject' => 'First todo' },
                                                 '1' => { 'id' => 2, '_destroy' => '1', 'subject' => 'Second todo' } } }

      compatible_xhr_request :put, :update, :issue => parameters, :project_id => issue.project, :id => issue.to_param
      issue.reload
      assert_equal issue.status, closed_status
      assert_equal 2, issue.checklists.size
    end
  ensure
    issue.update_attributes(:status_id => initial_status)
  end

  def test_should_not_change_done_ratio
    issue = Issue.find(1)
    with_checklists_settings('issue_done_ratio' => '1') do
      parameters = { checklists_attributes: { '0' => { 'id' => 1, 'is_done' => '1', 'subject' => 'First todo' },
                                              '1' => { 'id' => 2, 'is_done' => '0', 'subject' => 'Second todo' } } }

      compatible_request :put, :update, issue: parameters, project_id: issue.project, id: issue.to_param
      assert_equal issue.reload.done_ratio, 50

      parameters = { checklists_attributes: { '2' => { 'is_done' => '0', 'subject' => 'New Section', 'is_section' => 'true' },
                                              '0' => { 'id' => 1, 'is_done' => '1', 'subject' => 'First todo' },
                                              '1' => { 'id' => 2, 'is_done' => '0', 'subject' => 'Second todo' } } }

      compatible_request :put, :update, issue: parameters, project_id: issue.project, id: issue.to_param
      assert_equal issue.reload.done_ratio, 50
    end
  end

  def test_added_attachment_shows_in_log_once
    Setting[:plugin_redmine_checklists] = { :save_log => 1, :issue_done_ratio => 0 }
    set_tmp_attachments_directory
    parameters = { :tracker_id => 2,
                   :checklists_attributes => {
                     '0' => { 'is_done' => '0', 'subject' => 'First' },
                     '1' => { 'is_done' => '0', 'subject' => 'Second' } } }
    @request.session[:user_id] = 1
    issue = Issue.find(1)
    compatible_request :post, :update, :issue => parameters,
                                       :attachments => { '1' => { 'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file' } },
                                       :project_id => issue.project,
                                       :id => issue.to_param
    assert_response :redirect
    assert_equal 1, Journal.last.details.where(:property => 'attachment').count
  end
  def test_update_with_delete_write_to_journal
    Setting[:plugin_redmine_checklists] = { :save_log => 1, :issue_done_ratio => 0 }
    @request.session[:user_id] = 1
    issue = Issue.find(1)
    EmailAddress.create!(:user_id => 2, :address => 'test@example.com') if Redmine::VERSION.to_s >= '3.0'

    # Create new checklist
    compatible_xhr_request :put, :update,
                           :issue => { :notes => 'fix me',
                                       :checklists_attributes => { '0' => { 'is_done' => '0', 'subject' => 'Five' } } },
                           :project_id => issue.project,
                           :id => issue.to_param
    assert_response :redirect
    issue.reload
    # Delete new checklist
    compatible_xhr_request :put, :update,
                           :issue => { :checklists_attributes => { '0' => { 'id' => issue.checklists.max.id, '_destroy' => '1', 'subject' => 'First todo' } } },
                           :project_id => issue.project,
                           :id => issue.to_param
    assert_response :redirect

    compatible_request :get, :show, :id => issue.id
    assert_response :success
    assert_select "#change-#{issue.journals.last.id} .details li", 'Checklist item deleted (Five)'
  end

  def test_history_dont_show_old_format_checklists
    Setting[:plugin_redmine_checklists] = { :save_log => 1, :issue_done_ratio => 0 }
    @request.session[:user_id] = 1
    issue = Issue.find(1)
    issue.journals.create!(:user_id => 1)
    issue.journals.last.details.create!(:property =>  'attr',
                                        :prop_key =>  'checklist',
                                        :old_value => '[ ] TEST',
                                        :value =>     '[x] TEST')

    compatible_request :post, :show, :id => issue.id
    assert_response :success
    last_journal = issue.journals.last
    assert_equal last_journal.details.size, 1
    assert_equal last_journal.details.first.prop_key, 'checklist'
    assert_select "#change-#{last_journal.id} .details li", 'Checklist item changed from [ ] TEST to [x] TEST'
  end

  def test_empty_update_dont_write_to_journal
    @request.session[:user_id] = 1
    issue = Issue.find(1)
    journals_before = issue.journals.count
    compatible_request :post, :update, :issue => {}, :id => issue.to_param, :project_id => issue.project
    assert_response :redirect
    assert_equal journals_before, issue.reload.journals.count
  end

  def test_create_issue_without_checklists
    @request.session[:user_id] = 1
    assert_difference 'Issue.count' do
      compatible_request :post, :create, :project_id => 1, :issue => { :tracker_id => 3,
                                                                       :status_id => 2,
                                                                       :subject => 'NEW issue without checklists',
                                                                       :description => 'This is the description'
                                                                     }
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

    issue = Issue.find_by_subject('NEW issue without checklists')
    assert_not_nil issue
  end

  def test_create_issue_with_checklists
    @request.session[:user_id] = 1
    assert_difference 'Issue.count' do
      compatible_request :post, :create, :project_id => 1, :issue => { :tracker_id => 3,
                                                                       :status_id => 2,
                                                                       :subject => 'NEW issue with checklists',
                                                                       :description => 'This is the description',
                                                                       :checklists_attributes => { '0' => { 'is_done' => '0', 'subject' => 'item 001', 'position' => '1' } }
                                                                     }
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

    issue = Issue.find_by_subject('NEW issue with checklists')
    assert_equal 1, issue.checklists.count
    assert_equal 'item 001', issue.checklists.last.subject
    assert_not_nil issue
  end

  def test_create_issue_using_json
    old_value = Setting.rest_api_enabled
    Setting.rest_api_enabled = '1'
    @request.session[:user_id] = 1
    assert_difference 'Issue.count' do
      compatible_request :post, :create, :format => :json, :project_id => 1, :issue => { :tracker_id => 3,
                                                                                         :status_id => 2,
                                                                                         :subject => 'NEW JSON issue',
                                                                                         :description => 'This is the description',
                                                                                         :checklists_attributes => [{ :is_done => 0, :subject => 'JSON checklist' }]
                                                                                       },
                                                                             :key => User.find(1).api_key
    end
    assert_response :created

    issue = Issue.find_by_subject('NEW JSON issue')
    assert_not_nil issue
    assert_equal 1, issue.checklists.count
  ensure
    Setting.rest_api_enabled = old_value
  end

  def test_history_displaying_for_checklist
    @request.session[:user_id] = 1
    Setting[:plugin_redmine_checklists] = { save_log: 1, issue_done_ratio: 0 }

    issue = Issue.find(1)
    journal = issue.journals.create!(user_id: 1)
    journal.details.create!(:property =>  'attr',
                            :prop_key =>  'checklist',
                            :old_value => '[ ] TEST',
                            :value =>     '[x] TEST')

    # With permissions
    @request.session[:user_id] = 1
    compatible_request :get, :show, id: issue.id
    assert_response :success
    assert_include 'changed from [ ] TEST to [x] TEST', response.body

    # Without permissions
    @request.session[:user_id] = 5
    compatible_request :get, :show, id: issue.id
    assert_response :success
    assert_not_include 'changed from [ ] TEST to [x] TEST', response.body
  end
  def test_save_order_position
    parameters = { :checklists_attributes => { '0' => { 'id' => 1, 'is_done' => '0', 'subject' => 'First todo', 'position' => '0' },
                                               '1' => { 'is_done' => '1', 'subject' => 'New checklist', 'position' => '1' },
                                               '2' => { 'id' => 2, 'is_done' => '0', 'subject' => 'Second todo', 'position' => '2' } } }

    issue = Issue.find(1)
    @request.session[:user_id] = 1
    compatible_xhr_request :put, :update, :issue => parameters, :project_id => issue.project, :id => issue.to_param
    assert_equal 0, Checklist.find(1).position
    assert_equal 2, Checklist.find(2).position
    assert_equal 1, Checklist.last.position
  end

  def test_add_default_project_template_to_issue
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @template = ChecklistTemplate.create!(:name => 'Default', :template_items => 'def 1', :is_default => true, :user => User.find(1), :project => @project)
    compatible_request :get, :new, :project_id => @project.id
    assert_response :success
    assert_select 'span.checklist-subject', 'def 1'
  ensure
    @template.destroy
  end

  def test_add_default_tracker_project_template_to_issue
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @tracker = @project.trackers.first
    @p_template = ChecklistTemplate.create!(:name => 'Default P', :template_items => 'project 1', :is_default => true, :user => User.find(1), :project => @project)
    @t_template = ChecklistTemplate.create!(:name => 'Default T', :template_items => 'tracker 1', :is_default => true,
                                            :tracker_id => @tracker.id, :user => User.find(1), :project => @project)
    compatible_request :get, :new, :project_id => @project.id
    assert_response :success
    assert_select 'span.checklist-subject', 'tracker 1'
  ensure
    @p_template.destroy
    @t_template.destroy
  end

  def test_apply_default_tracker_template_on_tracker_change
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @tracker = @project.trackers.first
    @t_template = ChecklistTemplate.create!(:name => 'Default T', :template_items => 'tracker-1', :is_default => true,
                                            :tracker_id => @tracker.id, :user => User.find(1), :project => @project)

    parameters = { :tracker_id => @tracker.id + 1, :checklists_attributes => { '0' => { 'is_done' => '0', 'subject' => '', '_destroy' => 'false', 'position' => '1', 'id' => '' } } }

    # Tracker without default list
    compatible_xhr_request :post, :new, :issue => parameters, :project_id => @project
    assert_response :success
    assert_no_match %r{tracker-1}, response.body

    # Tracker with default list
    compatible_xhr_request :post, :new, :issue => parameters.merge(:tracker_id => @tracker.id), :project_id => @project
    assert_response :success
    assert_match 'tracker-1', response.body

    # Tracker with custom checklist
    compatible_xhr_request :post, :new, :issue => { :tracker_id => @tracker.id, :checklists_attributes => { '0' => { 'is_done' => '0', 'subject' => 'CUSTOM', '_destroy' => 'false', 'position' => '1', 'id' => '' } } }, :project_id => @project
    assert_response :success
    assert_match 'CUSTOM', response.body
  ensure
    @t_template.destroy
  end

  def test_copy_subtask_with_checklist
    parent = Issue.find(1)
    child  = Issue.find(2)
    child.parent_issue_id = parent.id
    child.fixed_version_id = nil
    child.save

    check_attrs = { :checklists_attributes => { '0' => { 'is_done' => '0', 'subject' => 'First todo', '_destroy' => 'false', 'position' => '1', 'id' => '' },
                                                '1' => { 'is_done' => '1', 'subject' => 'Second todo', '_destroy' => 'false', 'position' => '2', 'id' => '' } } }
    compatible_request :post, :create, :copy_from => parent.id, :link_copy => 1, :copy_subtasks => 1, :issue => parent.attributes.except(:created_on, :updated_on).merge(check_attrs)
    parent_copy = parent.reload.relations.first.issue_to
    assert_not_nil parent_copy
    assert_equal check_attrs[:checklists_attributes].size, parent_copy.checklists.size

    child_copy = parent_copy.children.first
    assert_not_nil child_copy
    assert_equal child.checklists.size, child_copy.checklists.size
  ensure
    Issue.find(2).update_attributes(:parent_id => nil, :fixed_version_id => 2)
  end
end
