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

class LeaveTypesControllerTest < ActionController::TestCase
  include Redmine::I18n
  include RedminePeople::TestCase::TestHelper

  fixtures :users
  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/', [:leave_types, :dayoffs])

  def setup
    Setting.plugin_redmine_people = {}

    @leave_type_params =  {
      name: 'Test Leave Type',
      paid: false,
      approvable: false,
      color: LeaveType::COLORS[:red]
    }
  end

  def test_get_new_without_authorization
    compatible_request :get, :new
    assert_response :redirect
  end

  def test_get_edit_without_authorization
    compatible_request :get, :edit, id: 1
    assert_response :redirect
  end

  def test_create_without_authorization
    compatible_request :post, :create, leave_type: @leave_type_params
    assert_response :redirect
  end

  def test_update_without_authorization
    compatible_request :post, :update, id: 1, leave_type: @leave_type_params
    assert_response :redirect
  end

  def test_destroy_without_authorization
    compatible_request :delete, :destroy, id: 1
    assert_response :redirect
  end

  def test_get_new_with_regular_user
    @request.session[:user_id] = 2
    compatible_request :get, :new
    assert_response :forbidden
  end

  def test_get_edit_with_regular_user
    @request.session[:user_id] = 2
    compatible_request :get, :edit, id: 1
    assert_response :forbidden
  end

  def test_create_with_regular_user
    @request.session[:user_id] = 2
    compatible_request :post, :create, leave_type: @leave_type_params
    assert_response :forbidden
  end

  def test_update_with_regular_user
    @request.session[:user_id] = 2
    compatible_request :post, :update, id: 1, leave_type: @leave_type_params
    assert_response :forbidden
  end

  def test_destroy_with_regular_user
    @request.session[:user_id] = 2
    compatible_request :delete, :destroy, id: 1
    assert_response :forbidden
  end

  def test_get_new_with_admin
    @request.session[:user_id] = 1
    compatible_request :get, :new
    assert_response :success
  end

  def test_get_edit_with_admin
    @request.session[:user_id] = 1
    compatible_request :get, :edit, id: 1
    assert_response :success
  end

  def test_create_with_admin
    @request.session[:user_id] = 1
    assert_difference('LeaveType.count') do
      compatible_request :post, :create, leave_type: @leave_type_params
    end
    assert_redirected_to people_settings_path(tab: 'leave_types')
    assert_equal flash[:notice], l(:notice_successful_create)
  end

  def test_update_with_admin
    @request.session[:user_id] = 1
    leave_type = LeaveType.find(1)
    compatible_request :post, :update, id: leave_type.id, leave_type: @leave_type_params
    assert_redirected_to people_settings_path(tab: 'leave_types')
    assert_equal flash[:notice], l(:notice_successful_update)

    leave_type.reload
    @leave_type_params.each do |key, value|
      assert_equal leave_type[key], value
    end
  end

  def test_destroy_leave_type_without_dependents
    @request.session[:user_id] = 1
    assert_difference('LeaveType.count', -1) do
      compatible_request :delete, :destroy, id: 4
    end
    assert_redirected_to people_settings_path(tab: 'leave_types')
    assert_equal flash[:notice], l(:notice_leave_type_successfully_destroyed)
  end

  def test_destroy_leave_type_with_dependents
    @request.session[:user_id] = 1
    assert_difference('LeaveType.count', 0) do
      compatible_request :delete, :destroy, id: 1
    end
    assert_redirected_to people_settings_path(tab: 'leave_types')
    assert flash[:error].present?
  end

  def test_create_with_blank_name
    @request.session[:user_id] = 1
    assert_difference('LeaveType.count', 0) do
      compatible_request :post, :create, leave_type: @leave_type_params.merge(name: '')
    end
    assert_response :success
  end

  def test_update_with_blank_name
    @request.session[:user_id] = 1
    leave_type = LeaveType.find(1)
    compatible_request :post, :update, id: leave_type.id, leave_type: @leave_type_params.merge(name: '')
    assert leave_type.reload.name.present?
  end
end
