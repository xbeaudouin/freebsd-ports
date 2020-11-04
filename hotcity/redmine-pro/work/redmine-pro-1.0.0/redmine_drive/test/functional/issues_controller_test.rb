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

class IssuesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :versions, :trackers, :projects_trackers, :enabled_modules, :enumerations,
           :issues, :issue_statuses, :journals, :journal_details

  create_fixtures(redmine_drive_fixtures_directory,
                  [:drive_entries, :issue_drive_files, :attachments, :viewings])
  create_fixtures(redmine_drive_fixtures_directory, [:tags, :taggings])

  def setup
    set_redmine_drive_fixtures_attachments_directory
    @admin = User.find(1)
    @issue = Issue.find(1)
    @project = Project.find(1)
    EnabledModule.create(project: @project, name: 'drive')
  end

  def test_should_add_shared_files
    @request.session[:user_id] = @admin.id
    assert_difference -> { @issue.shared_files.size } do
      assert_difference 'Journal.count' do
        compatible_request :put, :update, id: @issue.id,
                           issue: { shared_files_attributes: { '0' => { 'drive_entry_id' => '1' } } }
      end
    end
    assert_redirected_to action: 'show', id: @issue.id
  end

  def test_should_delete_shared_files
    @request.session[:user_id] = @admin.id
    assert_difference -> { @issue.shared_files.size }, -1 do
      assert_difference 'Journal.count' do
        compatible_request :put, :update, id: @issue.id,
                           issue: { shared_files_attributes: { '0' => { id: '1', 'drive_entry_id' => '1', _destroy: '1' } } }
      end
    end
    assert_redirected_to action: 'show', id: @issue.id
  end
end
