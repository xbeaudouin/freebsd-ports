# encoding: utf-8
#
# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class AutoCompletesControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users
  fixtures :email_addresses if Redmine::VERSION.to_s >= '3.0'

  def test_people_users_autocomplete_with_empty_query_string
    compatible_xhr_request :get, :people_users,  q: ''
    assert_response :success
    assert ActiveSupport::JSON.decode(response.body).size

    users = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Array, users
    assert users.size > 0
  end

  def test_people_users_autocomplete
    @request.session[:user_id] = 2
    should_get_users [2], q: 'smi'
    should_get_users [3], q: 'lop'
    should_get_users [1, 3, 7, 8, 9], q: 'a'
    should_get_users [3, 4, 8, 9], q: 'er'
  end

  private

  def should_get_users(expected_user_ids, params)
    compatible_xhr_request :get, :people_users, params
    assert_response :success
    assert_equal expected_user_ids, ActiveSupport::JSON.decode(response.body).map { |u| u['id'] }.sort
  end
end
