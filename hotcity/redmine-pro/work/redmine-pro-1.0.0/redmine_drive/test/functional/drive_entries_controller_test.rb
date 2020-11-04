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

# TODO: Each test should make no more than one request because the instance of the controller is only one inside each test case.
class DriveEntriesControllerTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :versions, :trackers, :projects_trackers, :enabled_modules, :enumerations

  create_fixtures(redmine_drive_fixtures_directory,
                  [:drive_entries, :issue_drive_files, :attachments, :viewings])
  create_fixtures(redmine_drive_fixtures_directory, [:tags, :taggings])

  def setup
    set_redmine_drive_fixtures_attachments_directory

    @admin = User.find(1)
    @user = User.find(2)

    @project = Project.find(1)
    @second_project = Project.find(2)

    @project_folder = RedmineDrive::VirtualFileSystem::ProjectFolder.new(@project)
    @root_folder_children_ids = ['1', '2', '3', @project_folder.id]

    EnabledModule.create(project: @project, name: 'drive')

    @drive_entry_params = {
      drive_entry: {
        name: 'Test',
        tag_list: %w[new test],
        description: 'Some description'
      }
    }
  end

  # === Action :index ===

  def test_should_get_index_global
    @request.session[:user_id] = @admin.id
    should_get_index @root_folder_children_ids
  end

  def test_should_get_index_for_admin
    @request.session[:user_id] = @admin.id
    should_get_index @root_folder_children_ids
  end

  def test_should_get_index_with_permission_view_drive_entries
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_drive_entries
    should_get_index @root_folder_children_ids
  end

  def test_should_get_index_for_anonymous_with_permission_view_drive_entries
    Role.find(5).add_permission! :view_drive_entries
    should_get_index @root_folder_children_ids
  end

  def test_should_not_access_index_without_permission_view_drive_entries
    @request.session[:user_id] = @user.id
    compatible_request :get, :index
    assert_response :forbidden
  end

  def test_should_not_access_index_for_anonymous
    compatible_request :get, :index
    assert_response :redirect
  end

  def test_should_get_index_with_nodata
    @request.session[:user_id] = @admin.id
    should_get_index [], current_folder_id: 3
  end

  def test_should_get_index_for_project_folder
    @request.session[:user_id] = @admin.id
    should_get_index ['11'], project_id: @project.id, current_folder_id: 8
  end

  def test_should_not_get_index_with_disabled_drive_plugin
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, project_id: @second_project.id
    assert_response :forbidden
  end
  def test_should_get_index_by_ajax_for_quick_search
    @request.session[:user_id] = @admin.id
    compatible_xhr_request :get, :index, search: 'logo'
    assert_response :success
    assert_equal ['1'], drive_entry_ids_in_list.sort
  end

  def test_index_global_with_filter_by_name
    @request.session[:user_id] = @admin.id
    should_get_index ['1'], set_filter: '1', f: ['name'], op: { 'name' => '~' }, v: { 'name' => ['.png'] }
  end

  def test_index_for_project_folder_with_filter_by_name
    @request.session[:user_id] = @admin.id
    should_get_index [], {
      project_id: @project.id,
      current_folder_id: 8,
      set_filter: '1',
      f: ['name'],
      op: { 'name' => '~' },
      v: { 'name' => ['.png'] }
    }
  end
  def test_index_with_filter_by_tags
    @request.session[:user_id] = @admin.id
    should_get_index %w(2 3), set_filter: '1', f: ['tags'], op: { 'tags' => '=' }, v: { 'tags' => ['folder'] }
  end

  def test_index_with_filter_by_author
    @request.session[:user_id] = @admin.id
    should_get_index %w(1 2 3), set_filter: '1', f: ['author_id'], op: { 'author_id' => '=' }, v: { 'author_id' => ['1'] }
  end

  def test_index_with_filter_by_description
    @request.session[:user_id] = @admin.id
    should_get_index ['2'], {
      set_filter: '1',
      f: ['description'],
      op: { 'description' => '~' },
      v: { 'description' => ['company'] }
    }
  end

  def test_index_with_filter_by_shared
    @request.session[:user_id] = @admin.id
    should_get_index %w(1 2), set_filter: '1', f: ['shared'], op: { 'shared' => '=' }, v: { 'shared' => ['1'] }
  end

  def test_index_with_filter_by_updated_at
    @request.session[:user_id] = @admin.id
    should_get_index %w(1 2 3), {
      set_filter: '1',
      f: ['updated_at'],
      op: { 'updated_at' => '=' },
      v: { 'updated_at' => ['2019-01-01'] }
    }
  end

  def test_index_with_filter_by_downloads
    @request.session[:user_id] = @admin.id
    params = { project_id: @project.id, set_filter: '1', f: ['downloads'] }
    should_get_index %w(9 10), params.merge(op: { 'downloads' => '*' })
    should_get_index ['10'], params.merge(op: { 'downloads' => '!*' })
    should_get_index %w(9 10), params.merge(op: { 'downloads' => '><' }, v: { 'downloads' => ['0', '2'] })
    should_get_index ['9'], params.merge(op: { 'downloads' => '><' }, v: { 'downloads' => ['1', '2'] })
    should_get_index ['10'], params.merge(op: { 'downloads' => '=' }, v: { 'downloads' => ['0'] })
    should_get_index [], params.merge(op: { 'downloads' => '>=' }, v: { 'downloads' => ['3'] })
  end

  def test_index_with_filter_by_filesize
    @request.session[:user_id] = @admin.id
    should_get_index ['1'], set_filter: '1', f: ['filesize'], op: { 'filesize' => '<=' }, v: { 'filesize' => ['4000'] }
  end

  def test_index_with_filter_by_created_at
    @request.session[:user_id] = @admin.id
    should_get_index %w(1 2 3), {
      set_filter: '1',
      f: ['created_at'],
      op: { 'created_at' => '<=' },
      v: { 'created_at' => ['2019-01-01'] }
    }
  end

  def test_should_get_index_with_folders_before_files
    @request.session[:user_id] = @admin.id
    should_get_index @root_folder_children_ids

    drive_entries = drive_entries_in_list
    assert drive_entries.first(3).all?(&:folder?)
    assert drive_entries.last.file?
  end

  def test_should_get_index_with_folders_before_files_and_sort_by_size_desc
    @request.session[:user_id] = @admin.id
    should_get_index @root_folder_children_ids, sort: 'size:desc'

    drive_entries = drive_entries_in_list
    assert drive_entries.first(3).all?(&:folder?)
    assert drive_entries.last.file?
  end

  # === Action :show ===

  def test_should_get_show_for_admin
    @request.session[:user_id] = @admin.id
    should_get_show_folder id: 2
    should_get_show_folder id: 2, token: DriveEntry.find(2).public_link_token
    should_get_show_file id: 9, token: DriveEntry.find(9).public_link_token
  end

  def test_should_get_show_for_regular_user
    @request.session[:user_id] = @user.id
    should_get_show_folder id: 2, token: DriveEntry.find(2).public_link_token
    should_get_show_file id: 9, token: DriveEntry.find(9).public_link_token
  end

  def test_should_get_show_for_regular_user_with_permission_view_drive_entries
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_drive_entries
    should_get_show_folder id: 2
  end

  def test_should_get_show_for_anonymous_with_permission_view_drive_entries
    Role.find(5).add_permission! :view_drive_entries
    should_get_show_folder id: 2
  end

  def test_should_get_show_for_anonymous
    should_get_show_folder id: 2, token: DriveEntry.find(2).public_link_token
    should_get_show_file id: 9, token: DriveEntry.find(9).public_link_token
  end

  def test_should_not_get_show_for_admin
    @request.session[:user_id] = @user.id
    # File from the project where disabled RedmineDrive
    should_not_get_show id: 11, token: DriveEntry.find(11).public_link_token
  end

  def test_should_not_get_show_for_regular_user
    @request.session[:user_id] = @user.id
    should_not_get_show id: 2
    should_not_get_show id: 9
    should_not_get_show id: 2, token: 'invalid token'

    # Unshared folder
    should_not_get_show id: 3, token: DriveEntry.find(3).public_link_token
    # Unshared file
    should_not_get_show id: 10, token: DriveEntry.find(10).public_link_token

    # File from the project where disabled RedmineDrive
    should_not_get_show id: 11, token: DriveEntry.find(11).public_link_token
  end

  def test_should_not_get_show_for_anonymous
    @request.session[:user_id] = @user.id
    should_not_get_show id: 2
    should_not_get_show id: 9
    should_not_get_show id: 2, token: 'invalid token'

    # Unshared folder
    should_not_get_show id: 3, token: DriveEntry.find(3).public_link_token
    # Unshared file
    should_not_get_show id: 10, token: DriveEntry.find(10).public_link_token

    # File from the project where disabled RedmineDrive
    should_not_get_show id: 11, token: DriveEntry.find(11).public_link_token
  end

  def test_sub_folder_access_of_shared_folder
    # Should access to the sub-folder of the shared folder
    should_get_show_folder id: 2, token: DriveEntry.find(2).public_link_token, current_folder_id: 4
    # There should be no access to another folder through the shared folder token
    should_not_get_show id: 2, token: DriveEntry.find(2).public_link_token, current_folder_id: 3
  end
  def test_show_by_time_link
    return if Rails.version < '4.1' # travel_to helper added in Rails  4.1

    expiration_date = Date.new(2019, 5, 20)
    timestamp = expiration_date.to_s(:number)

    travel_to expiration_date.prev_day do
      should_get_show_folder id: 2, token: DriveEntry.find(2).public_link_token(timestamp), timestamp: timestamp
      should_get_show_file id: 9, token: DriveEntry.find(9).public_link_token(timestamp), timestamp: timestamp
    end

    travel_to expiration_date do
      should_not_get_show id: 2, token: DriveEntry.find(2).public_link_token(timestamp), timestamp: timestamp
      should_not_get_show id: 9, token: DriveEntry.find(9).public_link_token(timestamp), timestamp: timestamp
    end

    travel_to expiration_date.next_day do
      should_not_get_show id: 2, token: DriveEntry.find(2).public_link_token(timestamp), timestamp: timestamp
      should_not_get_show id: 9, token: DriveEntry.find(9).public_link_token(timestamp), timestamp: timestamp
    end
  end

  # === Action :new_folder ===

  def test_should_get_new_folder_for_admin
    @request.session[:user_id] = @admin.id
    should_get_new_folder
    should_get_new_folder project_id: @project.id
  end

  def test_should_get_new_folder_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :add_drive_entries
    should_get_new_folder
    should_get_new_folder project_id: @project.id
  end

  def test_should_not_get_new_folder_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :new_folder
    assert_response :forbidden
  end

  def test_should_not_get_new_folder_for_anonymous
    compatible_xhr_request :get, :new_folder
    assert_response :unauthorized
  end

  # === Action :create_folder ===

  def test_should_create_folder_for_admin
    @request.session[:user_id] = @admin.id
    should_create_folder @drive_entry_params
  end

  def test_should_create_folder_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :add_drive_entries
    should_create_folder @drive_entry_params
  end

  def test_should_not_create_folder_without_permission
    @request.session[:user_id] = @user.id
    should_not_create_folder :forbidden, @drive_entry_params
  end

  def test_should_not_create_folder_without_name
    @request.session[:user_id] = @admin.id
    should_not_create_folder :success, @drive_entry_params.merge(drive_entry: { name: nil })
  end

  def test_should_not_create_folder_for_anonymous
    should_not_create_folder :unauthorized, @drive_entry_params
  end

  def test_should_not_create_folder_with_the_same_name
    @request.session[:user_id] = @admin.id
    should_not_create_folder :success, drive_entry: { name: 'Reports' }
  end

  def test_should_create_folder_with_the_same_name_as_file
    @request.session[:user_id] = @admin.id
    should_create_folder drive_entry: { name: 'logo.png' }
  end

  # === Action :new_files ===

  def test_should_get_new_files_for_admin
    @request.session[:user_id] = @admin.id
    should_get_modal :new_files
  end

  def test_should_get_new_files_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :add_drive_entries
    should_get_modal :new_files
  end

  def test_should_not_get_new_files_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :new_files
    assert_response :forbidden
  end

  def test_should_not_get_new_files_for_anonymous
    compatible_xhr_request :get, :new_files
    assert_response :unauthorized
  end

  # === Action :create_files ===

  def test_should_create_files_for_admin
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id
    attachment = Attachment.create!(file: uploaded_test_file('testfile.txt', 'text/plain'), author_id: @admin.id)
    should_create_files attachments: { '1' => { token: attachment.token } }
  end

  def test_should_create_several_files_for_admin
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id
    attachment_1 = Attachment.create!(file: uploaded_test_file('testfile.txt', 'text/plain'), author_id: @admin.id)
    attachment_2 = Attachment.create!(file: uploaded_test_file('iso8859-1.txt', 'text/plain'), author_id: @admin.id)
    should_create_files attachments: { '1' => { token: attachment_1.token }, '2' => { token: attachment_2.token }}
  end

  def test_should_create_files_with_permission
    set_tmp_attachments_directory
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :add_drive_entries
    attachment = Attachment.create!(file: uploaded_test_file('testfile.txt', 'text/plain'), author_id: @user.id)
    should_create_files attachments: { '1' => { token: attachment.token } }
  end

  def test_should_not_create_files_without_permission
    set_tmp_attachments_directory
    @request.session[:user_id] = @user.id
    attachment = Attachment.create!(file: uploaded_test_file('testfile.txt', 'text/plain'), author_id: @user.id)
    should_not_create_files :forbidden, attachments: { '1' => { token: attachment.token } }
  end

  def test_should_not_create_files_for_anonymous
    set_tmp_attachments_directory
    should_not_create_files :unauthorized, @drive_entry_params
    attachment = Attachment.create!(file: uploaded_test_file('testfile.txt', 'text/plain'), author_id: @user.id)
    should_not_create_files :unauthorized, attachments: { '1' => { token: attachment.token } }
  end

  def test_should_create_files_with_storage_size_setting
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id

    with_drive_settings 'storage_size' => DriveEntry.total_size / 1024 / 1024 + 1 do
      attachment = Attachment.create!(file: uploaded_test_file('testfile.txt', 'text/plain'), author_id: @admin.id)
      should_create_files attachments: { '1' => { token: attachment.token } }
    end
  end

  def test_should_not_create_files_with_storage_size_setting
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id

    with_drive_settings 'storage_size' => DriveEntry.total_size / 1024 / 1024 do
      attachment = Attachment.create!(file: uploaded_test_file('testfile.txt', 'text/plain'), author_id: @admin.id)
      should_not_create_files :success, attachments: { '1' => { token: attachment.token } }
    end
  end

  def test_should_create_file_with_incremented_name
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id
    assert_equal 0, DriveEntry.global.where('name = ?', 'logo (1).png').size
    attachment = Attachment.create!(file: mock_file_with_options(original_filename: 'logo.png'), author_id: @user.id)
    should_create_files attachments: { '1' => { token: attachment.token } }
    assert_equal 1, DriveEntry.global.where('name = ?', 'logo (1).png').size
  end

  def test_should_create_file_with_the_same_name_as_folder
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id
    assert_equal 1, DriveEntry.global.where('name = ?', 'Reports').size
    attachment = Attachment.create!(file: mock_file_with_options(original_filename: 'Reports'), author_id: @user.id)
    should_create_files attachments: { '1' => { token: attachment.token } }
    assert_equal 2, DriveEntry.global.where('name = ?', 'Reports').size
  end

  # === Action :edit ===

  def test_should_get_edit_file_for_admin
    @request.session[:user_id] = @admin.id
    should_get_modal :edit, ids: [1]
  end

  def test_should_get_edit_folder_for_admin
    @request.session[:user_id] = @admin.id
    should_get_modal :edit, ids: [2]
  end

  def test_should_get_edit_drive_entries_for_admin
    @request.session[:user_id] = @admin.id

    ids = [1, 2, 3]
    compatible_xhr_request :get, :edit, ids: ids
    assert_response :success
    root_folder = RedmineDrive::VirtualFileSystem.root_folder
    bulk_edit_path = bulk_edit_drive_entries_path(ids: ids, current_folder_id: root_folder.id)
    assert_equal "window.location = '#{bulk_edit_path}'", response.body
  end

  def test_should_get_edit_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_drive_entries
    should_get_modal :edit, ids: [1]
  end

  def test_should_not_get_edit_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :edit, ids: [1]
    assert_response :forbidden
  end

  def test_should_not_get_edit_for_anonymous
    compatible_xhr_request :get, :edit, ids: [1]
    assert_response :unauthorized
  end

  # === Action :share_modal ===

  def test_should_get_share_modal_for_admin
    @request.session[:user_id] = @admin.id
    should_get_modal :share_modal, id: 3, current_folder_id: RedmineDrive::VirtualFileSystem.root_folder.id
  end

  def test_should_get_share_modal_for_file
    @request.session[:user_id] = @admin.id
    should_get_modal :share_modal, id: 1, current_folder_id: RedmineDrive::VirtualFileSystem.root_folder.id
  end

  def test_should_get_share_modal_json_for_admin
    @request.session[:user_id] = @admin.id
    @request.headers[:accept] = 'application/json'
    compatible_xhr_request :get, :share_modal, {
      id: 3,
      expiration_date: '2020-01-01',
      current_folder_id: RedmineDrive::VirtualFileSystem.root_folder.id
    }
    assert_response :success
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert json['public_url'].present?
  end if Redmine::VERSION.to_s >= '3.0'

  def test_should_get_share_modal_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_drive_entries
    should_get_modal :share_modal, id: 3, current_folder_id: RedmineDrive::VirtualFileSystem.root_folder.id
  end

  def test_should_not_get_share_modal_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :share_modal, id: 3, current_folder_id: RedmineDrive::VirtualFileSystem.root_folder.id
    assert_response :forbidden
  end

  def test_should_not_get_share_modal_for_anonymous
    compatible_xhr_request :get, :share_modal, id: 3, current_folder_id: RedmineDrive::VirtualFileSystem.root_folder.id
    assert_response :unauthorized
  end

  def test_should_not_get_share_modal_json_for_anonymous
    @request.headers[:accept] = 'application/json'
    compatible_xhr_request :get, :share_modal, id: 3, current_folder_id: RedmineDrive::VirtualFileSystem.root_folder.id

    # Special check for compatibility with new versions of Redmine
    assert response.status == 401 || response.status == 403
  end

  # === Action :update ===

  def test_should_update_file_for_admin
    @request.session[:user_id] = @admin.id
    should_update @drive_entry_params.merge(id: 1)
  end

  def test_should_update_folder_for_admin
    @request.session[:user_id] = @admin.id
    should_update @drive_entry_params.merge(id: 2)
  end

  def test_should_update_drive_entry_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_drive_entries
    should_update @drive_entry_params.merge(id: 1)
  end

  def test_should_not_update_drive_entry_without_permission
    @request.session[:user_id] = @user.id
    should_not_update :forbidden, @drive_entry_params.merge(id: 1)
  end

  def test_should_not_update_drive_entry_for_anonymous
    should_not_update :unauthorized, @drive_entry_params.merge(id: 1)
  end

  def test_should_not_update_drive_entry_without_name
    @request.session[:user_id] = @admin.id
    should_not_update :success, @drive_entry_params.merge(id: 1, drive_entry: { name: nil })
  end

  def test_should_share_drive_entry
    @request.session[:user_id] = @admin.id
    should_update id: 3, drive_entry: { shared: true }
  end

  def test_should_deny_public_access_to_drive_entry
    @request.session[:user_id] = @admin.id
    @request.headers[:accept] = 'application/json'
    should_update id: 1, drive_entry: { shared: false }

    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_equal false, json['shared']
  end if Redmine::VERSION.to_s >= '3.0'

  def test_should_not_update_folder_with_the_same_name
    @request.session[:user_id] = @admin.id
    should_not_update :success, id: 3, drive_entry: { name: 'Docs' }
  end

  def test_should_update_folder_with_the_same_name_as_file
    @request.session[:user_id] = @admin.id
    should_update id: 3, drive_entry: { name: 'logo.png' }
  end

  # === Action :bulk_edit ===

  def test_should_get_bulk_edit_for_admin
    @request.session[:user_id] = @admin.id
    compatible_request :get, :bulk_edit, ids: [1, 2, 8]
    assert_response :success
  end

  def test_should_get_bulk_edit_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_drive_entries
    compatible_request :get, :bulk_edit, ids: [1, 2, 8]
    assert_response :success
  end

  def test_should_not_get_bulk_edit_without_permission
    @request.session[:user_id] = @user.id
    compatible_request :get, :bulk_edit, ids: [1, 2, 8]
    assert_response :forbidden
  end

  def test_should_not_get_bulk_edit_for_anonymous
    compatible_request :get, :bulk_edit, ids: [1, 2, 8]
    assert_response :redirect
  end

  # === Action :bulk_update ===

  def test_should_bulk_update_drive_entries_for_admin
    @request.session[:user_id] = @admin.id
    should_bulk_update ids: [1, 8], drive_entries: {
      '1' => @drive_entry_params[:drive_entry],
      '8' => @drive_entry_params[:drive_entry]
    }
  end

  def test_should_bulk_update_drive_entries_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_drive_entries
    should_bulk_update ids: [1, 8], drive_entries: {
      '1' => @drive_entry_params[:drive_entry],
      '8' => @drive_entry_params[:drive_entry]
    }
  end

  def test_should_not_bulk_update_drive_entries_without_permission
    @request.session[:user_id] = @user.id
    should_not_bulk_update :forbidden, ids: [1, 8], drive_entries: {
      '1' => @drive_entry_params[:drive_entry],
      '8' => @drive_entry_params[:drive_entry]
    }
  end

  def test_should_not_bulk_update_drive_entries_for_anonymous
    should_not_bulk_update :redirect, ids: [1, 8], drive_entries: {
      '1' => @drive_entry_params[:drive_entry],
      '8' => @drive_entry_params[:drive_entry]
    }
  end

  def test_should_not_bulk_update_folder_with_the_same_name
    @request.session[:user_id] = @admin.id
    should_not_bulk_update :success, ids: [2, 3], drive_entries: {
      '2' => { name: 'New filename' },
      '3' => { name: 'New filename' }
    }
  end

  def test_should_bulk_update_folder_with_the_same_name_as_file
    @request.session[:user_id] = @admin.id
    should_bulk_update ids: [1, 2], drive_entries: {
      '1' => { name: 'New filename' },
      '2' => { name: 'New filename' }
    }
  end

  # === Action :copy_modal ===

  def test_should_get_copy_modal_for_admin
    @request.session[:user_id] = @admin.id
    should_get_modal :copy_modal, ids: [1, 2]
  end

  def test_should_get_copy_modal_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :add_drive_entries
    should_get_modal :copy_modal, ids: [1, 2]
  end

  def test_should_not_get_copy_modal_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :copy_modal, ids: [1, 2]
    assert_response :forbidden
  end

  def test_should_not_get_copy_modal_for_anonymous
    compatible_xhr_request :get, :copy_modal, ids: [1, 2]
    assert_response :unauthorized
  end

  def test_should_not_get_copy_modal_with_incorrect_params
    @request.session[:user_id] = @admin.id
    compatible_xhr_request :get, :copy_modal
    assert_response :missing
  end

  # === Action :copy ===

  def test_should_copy_for_admin
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id
    should_copy_drive_entries 2, 4, ids: [1, 2], folder_id: 8
  end

  def test_should_copy_with_permission
    set_tmp_attachments_directory
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :add_drive_entries
    should_copy_drive_entries 2, 4, ids: [1, 2], folder_id: 8
  end

  def test_should_not_copy_without_permission
    set_tmp_attachments_directory
    @request.session[:user_id] = @user.id
    should_not_copy_drive_entries :forbidden, ids: [1, 2], folder_id: 8
  end

  def test_should_not_copy_for_anonymous
    set_tmp_attachments_directory
    should_not_copy_drive_entries :unauthorized, ids: [1, 2], folder_id: 8
  end

  def test_should_copy_and_add_postfix_when_there_are_drive_entry_with_the_same_name
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id
    drive_entry = DriveEntry.find(3)
    assert_equal 'Reports', drive_entry.name
    should_copy_drive_entries 1, 0, ids: [3], folder_id: 8

    children = DriveEntry.find(8).children.where('id != ?', 11).to_a
    assert_equal 1, children.size
    assert_equal 'Reports (1)', children.first.name
  end

  def test_should_copy_with_storage_size_setting
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id

    with_drive_settings 'storage_size' => DriveEntry.total_size / 1024 / 1024 + 1 do
      should_copy_drive_entries 0, 1, ids: [10], folder_id: 8
    end
  end

  def test_should_not_copy_with_storage_size_setting
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id

    with_drive_settings 'storage_size' => DriveEntry.total_size / 1024 / 1024 do
      should_not_copy_drive_entries :success, ids: [10], folder_id: 8
    end
  end

  def test_should_copy_to_project_folder
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id
    should_copy_drive_entries 2, 4, ids: [1, 2], folder_id: @project_folder.id
  end

  # === Action :move_modal ===

  def test_should_get_move_modal_for_admin
    @request.session[:user_id] = @admin.id
    should_get_modal :move_modal, ids: [1, 2]
  end

  def test_should_get_move_modal_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_drive_entries
    should_get_modal :move_modal, ids: [1, 2]
  end

  def test_should_not_get_move_modal_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :move_modal, ids: [1, 2]
    assert_response :forbidden
  end

  def test_should_not_get_move_modal_for_anonymous
    compatible_xhr_request :get, :move_modal, ids: [1, 2]
    assert_response :unauthorized
  end

  def test_should_not_get_move_modal_with_incorrect_params
    @request.session[:user_id] = @admin.id
    compatible_xhr_request :get, :move_modal
    assert_response :missing
  end

  # === Action :move ===

  def test_should_move_for_admin
    @request.session[:user_id] = @admin.id
    should_move_drive_entries ids: [1, 2], folder_id: 8
  end

  def test_should_move_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_drive_entries
    should_move_drive_entries ids: [1, 2], folder_id: 8
  end

  def test_should_not_move_without_permission
    @request.session[:user_id] = @user.id
    should_not_move_drive_entries :forbidden, ids: [1, 2], folder_id: 8
  end

  def test_should_not_move_for_anonymous
    should_not_move_drive_entries :unauthorized, ids: [1, 2], folder_id: 8
  end

  def test_should_move_and_add_postfix_when_there_are_drive_entry_with_the_same_name
    @request.session[:user_id] = @admin.id
    drive_entry = DriveEntry.find(3)
    assert_equal 'Reports', drive_entry.name
    should_move_drive_entries ids: [3], folder_id: 8
    assert_equal 'Reports (1)', drive_entry.reload.name
  end

  def test_should_move_to_project_folder
    @request.session[:user_id] = @admin.id
    should_move_drive_entries ids: [1, 2], folder_id: @project_folder.id
  end
  # === Action :tags_autocomplete ===

  def test_should_get_tags_autocomplete_for_admin
    @request.session[:user_id] = @admin.id
    check_get_tags_autocomplete
  end

  def test_should_get_tags_autocomplete_for_regular_user
    @request.session[:user_id] = @user.id
    check_get_tags_autocomplete
  end

  def test_should_not_get_tags_autocomplete_for_anonymous
    compatible_xhr_request :get, :tags_autocomplete, q: ''
    assert_response :unauthorized
  end

  # === Action :destroy ===

  def test_should_destroy_file_enries_for_admin
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id
    should_destroy_file_enries(-6, -4, ids: [1, 2])
  end

  def test_should_destroy_file_enries_with_permission
    set_tmp_attachments_directory
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :edit_drive_entries
    should_destroy_file_enries(-6, -4, ids: [1, 2])
  end

  def test_should_not_destroy_file_enries_without_permission
    @request.session[:user_id] = @user.id
    should_not_destroy_file_enries :forbidden, ids: [1, 2]
  end

  def test_should_not_destroy_file_enries_for_anonymous
    should_not_destroy_file_enries :redirect, ids: [1, 2]
  end

  def test_should_show_warning_on_delete_file_linked_to_issue
    @request.session[:user_id] = @admin.id
    should_not_destroy_file_enries :success, ids: [9]
    assert_match /ajax-modal/, response.body
  end

  def test_should_delete_file_linked_to_issue_after_confirmation
    set_tmp_attachments_directory
    @request.session[:user_id] = @admin.id
    should_destroy_file_enries(-1, -1, ids: [9], force_delete: true)
  end

  # === Action :download ===

  def test_should_download_for_admin
    @request.session[:user_id] = @admin.id
    should_download 'test-app.txt', 'text/plain', ids: [10]
    should_download 'redmine-drive.zip', 'application/zip', ids: [1, 2, 10]
  end
  def test_should_download_project_folder
    @request.session[:user_id] = @admin.id
    should_download 'redmine-drive.zip', 'application/zip', ids: [@project_folder.id]
  end

  def test_should_download_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_drive_entries
    should_download 'test-app.txt', 'text/plain', ids: [10]
    should_download 'redmine-drive.zip', 'application/zip', ids: [1, 2, 10]
  end

  def test_should_download_for_anonymous_with_permission
    Role.find(5).add_permission! :view_drive_entries
    should_download 'test-app.txt', 'text/plain', ids: [10]
    should_download 'redmine-drive.zip', 'application/zip', ids: [1, 2, 10]
  end

  def test_should_download_by_token
    # Should download the shared file
    should_download 'logo.png', 'image/png', ids: [1], id: 1, token: DriveEntry.find(1).public_link_token
    # Should download file from shared folder
    should_download 'management.ppt', 'application/vnd.ms-powerpoint',
                    ids: [7], id: 2, token: DriveEntry.find(2).public_link_token
  end

  def test_should_not_download_with_incorrect_params
    should_not_download :forbidden, ids: [1], id: 1, token: 'invalid token'
    should_not_download :forbidden, ids: [2], id: 1, token: DriveEntry.find(1).public_link_token
    should_not_download :missing, ids: [2], token: DriveEntry.find(1).public_link_token
    should_not_download :forbidden, ids: [1, 2], id: 1, token: DriveEntry.find(1).public_link_token
    # Unshared file
    should_not_download :forbidden, ids: [10], id: 10, token: DriveEntry.find(10).public_link_token
  end

  def test_should_not_download_without_permission
    @request.session[:user_id] = @user.id
    should_not_download :forbidden, ids: [10]
    should_not_download :forbidden, ids: [1, 2, 10]
  end

  def test_should_not_download_for_anonymous
    should_not_download :redirect, ids: [10]
    should_not_download :redirect, ids: [1, 2, 10]
  end

  # === Action :children ===

  def test_should_get_children_of_global_folder_for_admin
    @request.session[:user_id] = @admin.id
    should_get_children %w(4 5), folder_id: 2
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
    should_get_children ['11'], folder_id: 8, project_id: @project.id
  end

  def test_should_get_children_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_drive_entries
    should_get_children %w(4 5), folder_id: 2
  end

  def test_should_get_children_for_anonymous_with_permission
    Role.find(5).add_permission! :view_drive_entries
    should_get_children %w(4 5), folder_id: 2
  end

  def test_should_not_get_children_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :children, folder_id: 2
    assert_response :forbidden
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

  def test_should_get_children_with_filters_in_session
    @request.session[:user_id] = @admin.id
    @request.session[:drive_entry_query] = {
      project_id: nil,
      filters: { 'tags' => { operator: '=', values: ['folder'] } },
      group_by: nil,
      column_names: nil,
      totalable_names: [],
      sort: []
    }

    should_get_children %w(4 5), folder_id: 2
  end

  # === Action :sub_folders ===

  def test_should_get_sub_folders_for_admin
    @request.session[:user_id] = @admin.id
    should_get_sub_folders ['4'], folder_id: 2
    should_get_sub_folders [], folder_id: 4
  end

  def test_should_get_sub_folders_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_drive_entries
    should_get_sub_folders ['4'], folder_id: 2
    should_get_sub_folders [], folder_id: 4
  end

  def test_should_not_get_sub_folders_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :sub_folders
    assert_response :forbidden
  end

  def test_should_not_get_sub_folders_for_anonymous
    compatible_xhr_request :get, :sub_folders
    assert_response :unauthorized
  end

  private

  def should_get_modal(action, parameters = {})
    compatible_xhr_request :get, action, parameters
    assert_response :success
    assert_match /ajax-modal/, response.body
  end

  def compare_drive_entry_attributes(drive_entry, params)
    assert_equal params[:name], drive_entry.name if params[:name]
    assert_equal params[:tag_list].sort, drive_entry.tag_list.sort if params[:tag_list]
    assert_equal params[:description], drive_entry.description if params[:description]
    assert_equal params[:shared], drive_entry.shared if params[:shared]
  end

  def should_be_the_original(drive_entry, params)
    assert_not_equal params[:name], drive_entry.name if params[:name]
    assert_not_equal params[:tag_list].sort, drive_entry.tag_list.sort if params[:tag_list]
    assert_not_equal params[:description], drive_entry.description if params[:description]
    assert_not_equal params[:shared], drive_entry.shared if params[:shared]
  end

  # === Helpers for action :index ===

  def should_get_index(expected_drive_entry_ids, params = {})
    compatible_request :get, :index, params
    assert_response :success

    if expected_drive_entry_ids.blank?
      assert_select 'p.nodata'
    else
      assert_equal expected_drive_entry_ids.sort, drive_entry_ids_in_list.sort
    end
  end

  # === Helpers for action :show ===

  def should_get_show_folder(parameters = {})
    compatible_xhr_request :get, :show, parameters
    assert_response :success
  end

  def should_get_show_file(parameters = {})
    compatible_xhr_request :get, :show, parameters
    assert_redirected_to download_drive_entries_path(id: parameters[:id],
                                                    ids: [parameters[:id]],
                                                    timestamp: parameters[:timestamp],
                                                    token: parameters[:token])
  end

  def should_not_get_show(parameters = {})
    compatible_xhr_request :get, :show, parameters
    assert_response :forbidden
  end

  # === Helpers for action :new_folder ===

  def should_get_new_folder(parameters = {})
    should_get_modal :new_folder, parameters
  end

  # === Helpers for action :create_folder ===

  def should_create_folder(parameters)
    assert_difference('DriveEntry.folders.count') do
      compatible_xhr_request :post, :create_folder, parameters
    end
    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_create)
  end

  def should_not_create_folder(response_status, parameters)
    assert_difference('DriveEntry.folders.count', 0) do
      compatible_xhr_request :post, :create_folder, parameters
    end
    assert_response response_status
  end

  # === Helpers for action :create_files ===

  def should_create_files(parameters)
    assert_difference('DriveEntry.files.count', parameters[:attachments].size) do
      compatible_xhr_request :post, :create_files, parameters
    end
    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_create)
  end

  def should_not_create_files(response_status, parameters)
    assert_difference('DriveEntry.files.count', 0) do
      compatible_xhr_request :post, :create_files, parameters
    end
    assert_response response_status
  end

  # === Helpers for action :update ===

  def should_update(parameters)
    compatible_xhr_request :post, :update, parameters
    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_update)
    compare_drive_entry_attributes(DriveEntry.find(parameters[:id]), parameters[:drive_entry])
  end

  def should_not_update(response_status, parameters)
    compatible_xhr_request :post, :update, parameters
    assert_response response_status
    should_be_the_original(DriveEntry.find(parameters[:id]), parameters[:drive_entry])
  end

  # === Helpers for action :bulk_update ===

  def should_bulk_update(parameters)
    compatible_request :post, :bulk_update, parameters
    assert_response :redirect

    parameters[:drive_entries].each do |k, v|
      compare_drive_entry_attributes(DriveEntry.find(k), v)
    end
  end

  def should_not_bulk_update(response_status, parameters)
    compatible_request :post, :bulk_update, parameters
    assert_response response_status

    parameters[:drive_entries].each do |k, v|
      should_be_the_original(DriveEntry.find(k), v)
    end
  end

  # === Helpers for action :copy ===

  def should_copy_drive_entries(folders_difference, files_difference, parameters)
    folder = RedmineDrive::VirtualFileSystem.find_folder(parameters[:folder_id])
    assert_difference(-> { folder.children.size }, parameters[:ids].size) do
      assert_difference('DriveEntry.folders.count', folders_difference) do
        assert_difference('DriveEntry.files.count', files_difference) do
          compatible_xhr_request :post, :copy, parameters
        end
      end
    end

    assert_response :success
    assert_equal flash[:notice], l(:label_drive_notice_copying_completed)
  end

  def should_not_copy_drive_entries(response_status, parameters)
    assert_difference('DriveEntry.count', 0) do
      assert_difference('Attachment.count', 0) do
        compatible_xhr_request :post, :copy, parameters
        assert_response response_status
      end
    end
  end

  # === Helpers for action :move ===

  def should_move_drive_entries(parameters)
    compatible_xhr_request :post, :move, parameters
    assert_response :success
    assert_equal flash[:notice], l(:label_drive_notice_move_completed)

    folder = RedmineDrive::VirtualFileSystem.find_folder(parameters[:folder_id])
    DriveEntry.find(parameters[:ids]).each do |drive_entry|
      assert drive_entry.project_id == folder.project_id
      assert drive_entry.parent_id == folder.db_record_id
    end
  end

  def should_not_move_drive_entries(response_status, parameters)
    old_parent_ids = DriveEntry.order('id ASC').find(parameters[:ids]).map(&:parent_id)

    compatible_xhr_request :post, :move, parameters
    assert_response response_status

    new_parent_ids = DriveEntry.order('id ASC').find(parameters[:ids]).map(&:parent_id)
    assert_equal old_parent_ids, new_parent_ids
  end
  # === Helpers for action :tags_autocomplete ===

  def should_get_tags_autocomplete(expected_tags, parameters)
    compatible_xhr_request :get, :tags_autocomplete, parameters
    assert_response :success
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Array, json
    assert_equal expected_tags.to_a.sort, json.map { |tag| tag['id'] }.sort
  end

  def check_get_tags_autocomplete
    should_get_tags_autocomplete %w[folder file test], q: ''
    should_get_tags_autocomplete %w[folder file], q: 'f'
    should_get_tags_autocomplete %w[file], q: 'file'
    should_get_tags_autocomplete [], q: 'list'
  end

  # === Helpers for action :destroy ===

  def should_destroy_file_enries(file_enries_difference, attachments_difference, parameters)
    assert_difference('DriveEntry.count', file_enries_difference) do
      assert_difference('Attachment.count', attachments_difference) do
        compatible_request :delete, :destroy, parameters
      end
    end

    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_delete)
  end

  def should_not_destroy_file_enries(response_status, parameters)
    assert_difference('DriveEntry.count', 0) do
      assert_difference('Attachment.count', 0) do
        compatible_request :delete, :destroy, parameters
      end
    end

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

  # === Helpers for action :sub_folders ===

  def should_get_sub_folders(expected_drive_entry_ids, parameters = {})
    compatible_xhr_request :get, :sub_folders, parameters
    assert_response :success

    if expected_drive_entry_ids.blank?
      assert_empty response.body
    else
      assert_equal expected_drive_entry_ids.sort, drive_entry_ids_in_list('tr[id^="folder-"]').sort
    end
  end
end
