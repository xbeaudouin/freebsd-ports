# encoding: utf-8
#
# This file is a part of Redmine ZenEdit (redmine_zenedit) plugin,
# editing enhancement plugin for Redmine
#
# Copyright (C) 2011-2019 RedmineUP
# http://www.redmineup.com/
#
# redmine_zenedit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_zenedit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_zenedit.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class ZeneditControllerTest < ActionController::TestCase
  fixtures :projects, :issues, :issue_statuses, :issue_categories, :trackers, :projects_trackers,
           :users, :roles, :member_roles, :members, :enabled_modules, :workflows,
           :enumerations, :journals, :journal_details

  fixtures :email_addresses if Redmine::VERSION.to_s >= '3.0'

  def setup
    @request.session[:user_id] = 1
  end
  def test_users_autocomplete
    check_by_params :users_autocomplete, %w(dlopper jsmith), id: 1, q: ''
    check_by_params :users_autocomplete, %w(dlopper jsmith), project_id: 1, q: ''
    check_by_params :users_autocomplete, %w(dlopper jsmith), id:1, project_id: 1, q: ''
    check_by_params :users_autocomplete, ['jsmith'], id:1, q: 'smi'
    check_by_params :users_autocomplete, %w(dlopper admin someone miscuser8 miscuser9), id:1, q: 'a'
    check_by_params :users_autocomplete, %w(dlopper rhill miscuser8 miscuser9), id:1, q: 'er'

    check_by_params :users_autocomplete, [], id: 5, q: ''
    check_by_params :users_autocomplete, [], project_id: 3, q: ''
    check_by_params :users_autocomplete, %w(dlopper admin someone miscuser8 miscuser9), id: 5, q: 'a'
    check_by_params :users_autocomplete, ['admin'], id: 5, q: 'adm'
    check_by_params :users_autocomplete, ['admin'], project_id: 3, q: 'admin'
    check_by_params :users_autocomplete, [], id: 5, q: 'administrator'
    check_by_params :users_autocomplete, %w(miscuser8 miscuser9), project_id: 3, q: 'mis'
  end

  def test_issues_autocomplete
    check_by_params :issues_autocomplete, [14, 13, 12, 11, 10, 9, 8, 7, 6, 5], q: ''
    check_by_params :issues_autocomplete, [14], q: '14'
    check_by_params :issues_autocomplete, [], q: 'ab'
    check_by_params :issues_autocomplete, [12, 11, 8], q: 'closed'
  end

  private

  def check_by_params(action, expected_users, request_options)
    compatible_xhr_request :get, action, request_options
    assert_response :success
    actual_users = ActiveSupport::JSON.decode(response.body).map { |u| u['value'] }
    assert_equal expected_users, actual_users
  end
end
