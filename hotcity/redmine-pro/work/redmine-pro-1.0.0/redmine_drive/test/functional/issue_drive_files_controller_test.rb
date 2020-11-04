# encoding: utf-8
#
# This file is a part of Redmin Drive (redmine_drive) plugin,
# Filse storage plugin for redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_drive is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_drive is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_drive.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class IssueDriveFilesControllerTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :versions, :trackers, :projects_trackers, :enabled_modules, :enumerations,
           :issues, :issue_statuses, :journals, :journal_details

  create_fixtures(redmine_drive_fixtures_directory,
                  [:drive_entries, :issue_drive_files, :attachments, :viewings])
  create_fixtures(redmine_drive_fixtures_directory, [:tags, :taggings])

  def setup
    set_redmine_drive_fixtures_attachments_directory
    @admin = User.find(1)
    @user = User.find(2)
    @project = Project.find(1)
    @project_folder = RedmineDrive::VirtualFileSystem::ProjectFolder.new(@project)
    @root_folder = RedmineDrive::VirtualFileSystem.root_folder
    @root_folder_children_ids = ['1', '2', '3', @project_folder.id]
    EnabledModule.create(project: @project, name: 'drive')
  end

  # === Action :show ===

  def test_should_get_show_for_admin
    @request.session[:user_id] = @admin.id
    should_get_show id: 1
  end if Redmine::VERSION.to_s >= '3.3'

  def test_should_get_show_for_regular_user_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_issues
    should_get_show id: 1
  end if Redmine::VERSION.to_s >= '3.3'

  def test_should_get_show_for_anonymous_with_permission
    Role.find(5).add_permission! :view_issues
    should_get_show id: 1
  end if Redmine::VERSION.to_s >= '3.3'

  def test_should_not_get_show_for_regular_user_without_permission
    @request.session[:user_id] = @user.id
    Role.find(1).remove_permission! :view_issues
    should_not_get_show :forbidden, id: 1
  end if Redmine::VERSION.to_s >= '3.3'

  def test_should_not_get_show_for_anonymous_without_permission
    Role.find(5).remove_permission! :view_issues
    should_not_get_show :unauthorized, id: 1
  end if Redmine::VERSION.to_s >= '3.3'

  def test_should_get_show_for_old_redmine_versions
    @request.session[:user_id] = @admin.id
    compatible_request :get, :download, id: 1
    assert_response :success
    assert_equal 'application/msword', @response.content_type
    assert_equal %(attachment; filename="tests.doc"), @response.headers['Content-Disposition']
  end if Redmine::VERSION.to_s < '3.3'

  # === Action :download ===

  def test_should_download_for_admin
    @request.session[:user_id] = @admin.id
    should_download 'tests.doc', 'application/msword', id: 1
  end

  def test_should_download_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_issues
    should_download 'tests.doc', 'application/msword', id: 1
  end

  def test_should_download_for_anonymous_with_permission
    Role.find(5).add_permission! :view_issues
    should_download 'tests.doc', 'application/msword', id: 1
  end

  def test_should_not_download_without_permission
    @request.session[:user_id] = @user.id
    Role.find(1).remove_permission! :view_issues
    should_not_download :forbidden, id: 1
  end

  def test_should_not_download_for_anonymous_without_permission
    Role.find(5).remove_permission! :view_issues
    should_not_download :redirect, id: 1
  end

  # === Action :new ===

  def test_should_get_new_for_admin
    @request.session[:user_id] = @admin.id
    should_get_modal :new
  end

  def test_should_get_new_with_params_for_admin
    @request.session[:user_id] = @admin.id
    should_get_modal :new, issue_id: 1
  end

  def test_should_not_get_new_for_anonymous
    compatible_xhr_request :get, :new
    assert_response :unauthorized
  end

  # === Action :create ===

  def test_should_create_shared_files_for_admin
    @request.session[:user_id] = @admin.id
    should_create_shared_files ids: [1, 9], issue_id: 1
  end

  def test_should_create_shared_files_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_issues
    should_create_shared_files ids: [1, 9], issue_id: 1
  end

  def test_should_not_create_shared_files_without_permission
    @request.session[:user_id] = @user.id
    Role.find(1).remove_permission! :edit_issues
    should_not_create_shared_files :forbidden, ids: [1, 9], issue_id: 1
  end

  def test_should_not_create_shared_files_for_anonymous
    should_not_create_shared_files :unauthorized, ids: [1, 9], issue_id: 1
  end

  # === Action :add ===

  def test_should_get_add_for_admin
    @request.session[:user_id] = @admin.id
    compatible_xhr_request :get, :add, ids: [1, 9]
    assert_response :success
  end

  def test_should_not_get_add_for_anonymous
    compatible_xhr_request :get, :add, ids: [1, 9]
    assert_response :unauthorized
  end

  # === Action :destroy ===

  def test_should_destroy_shared_file_for_admin
    @request.session[:user_id] = @admin.id
    should_destroy_shared_file id: 1
  end

  def test_should_destroy_shared_file_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_issues
    should_destroy_shared_file id: 1
  end

  def test_should_not_destroy_shared_file_without_permission
    @request.session[:user_id] = @user.id
    Role.find(1).remove_permission! :edit_issues
    should_not_destroy_shared_file :forbidden, id: 1
  end

  def test_should_not_destroy_shared_file_for_anonymous
    should_not_destroy_shared_file :unauthorized, id: 1
  end
  # === Action :search ===

  def test_should_get_search_for_admin
    @request.session[:user_id] = @admin.id
    should_get_search %w(8 9 10), q: 'test'
  end

  def test_should_get_search_by_empty_string
    @request.session[:user_id] = @admin.id
    should_get_search @root_folder_children_ids, q: ''
  end

  def test_should_get_search_by_current_folder_id
    @request.session[:user_id] = @admin.id
    should_get_search @root_folder_children_ids, current_folder_id: @root_folder.id
  end

  def test_should_get_search_for_regular_user
    @request.session[:user_id] = @user.id
    should_get_search [], q: 'test'
  end

  def test_should_not_get_search_for_anonymous
    compatible_xhr_request :get, :search, q: 'test'
    assert_response :unauthorized
  end

  # === Action :children ===

  def test_should_get_children_of_global_folder_for_admin
    @request.session[:user_id] = @admin.id
    should_get_children %w(4 5), folder_id: 2, current_folder_id: @root_folder.id
  end

  def test_should_get_children_of_sub_folder_for_admin
    @request.session[:user_id] = @admin.id
    should_get_children %w(6 7), folder_id: 4, current_folder_id: 2
  end

  def test_should_get_children_of_empty_folder_for_admin
    @request.session[:user_id] = @admin.id
    should_get_children [], folder_id: 11
  end

  def test_should_get_children_of_project_folder_for_admin
    @request.session[:user_id] = @admin.id
    should_get_children ['11'], folder_id: 8, current_folder_id: @project_folder.id
  end

  def test_should_not_get_children_for_anonymous
    compatible_xhr_request :get, :children, folder_id: 2
    assert_response :unauthorized
  end

  def test_should_not_get_children_for_file
    @request.session[:user_id] = @admin.id
    compatible_xhr_request :get, :children, folder_id: 1
    assert_response :missing
  end

  def test_should_not_get_children_with_incorrect_params
    @request.session[:user_id] = @admin.id
    compatible_xhr_request :get, :children
    assert_response :missing
  end

  private

  def should_get_modal(action, parameters = {})
    compatible_xhr_request :get, action, parameters
    assert_response :success
    assert_match /ajax-modal/, response.body
  end

  # === Helpers for action :show ===

  def should_get_show(parameters = {})
    compatible_request :get, :show, parameters
    assert_response :success
    assert_equal 'text/html', @response.content_type
  end

  def should_not_get_show(response_status, parameters = {})
    compatible_xhr_request :get, :show, parameters
    assert_response response_status
  end

  # === Helpers for action :download ===

  def should_download(filename, file_type, parameters)
    compatible_request :get, :download, parameters
    assert_response :success
    assert_equal file_type, @response.content_type
    assert_equal %(attachment; filename="#{filename}"), @response.headers['Content-Disposition']
  end

  def should_not_download(response_status, parameters)
    compatible_request :get, :download, parameters
    assert_response response_status
  end

  # === Helpers for action :create ===

  def should_create_shared_files(parameters)
    assert_difference('IssueDriveFile.count') do
      assert_difference 'Journal.count' do
        compatible_xhr_request :post, :create, parameters
      end
    end
    assert_response :success
  end

  def should_not_create_shared_files(response_status, parameters)
    assert_difference('IssueDriveFile.count', 0) do
      compatible_xhr_request :post, :create, parameters
    end
    assert_response response_status
  end

  # === Helpers for action :destroy ===

  def should_destroy_shared_file(params)
    assert_difference 'IssueDriveFile.count', -1 do
      assert_difference 'Journal.count' do
        compatible_xhr_request :delete, :destroy, params
      end
    end
    assert_response :success
  end

  def should_not_destroy_shared_file(response_status, parameters)
    assert_difference 'IssueDriveFile.count', 0 do
      compatible_xhr_request :delete, :destroy, parameters
    end
    assert_response response_status
  end

  # === Helpers for action :search ===

  def should_get_search(expected_drive_entry_ids, parameters = {})
    compatible_xhr_request :get, :search, parameters
    assert_response :success
    assert_equal expected_drive_entry_ids.sort, drive_entry_ids_in_list('tr[id^="drive-entry-"]').sort
  end

  # === Helpers for action :children ===

  def should_get_children(expected_drive_entry_ids, parameters = {})
    compatible_xhr_request :get, :children, parameters
    assert_response :success

    if expected_drive_entry_ids.blank?
      assert_empty response.body
    else
      assert_equal expected_drive_entry_ids.sort, drive_entry_ids_in_list('tr[id^="drive-entry-"]').sort
    end
  end
end
