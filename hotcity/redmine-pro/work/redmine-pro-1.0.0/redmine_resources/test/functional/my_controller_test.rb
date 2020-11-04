# encoding: utf-8
#
# This file is a part of Redmine Resources (redmine_resources) plugin,
# resource allocation and management for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_resources is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_resources is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_resources.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class MyControllerTest < ActionController::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :auth_sources, :queries

  fixtures :email_addresses if Redmine::VERSION.to_s >= '3.0'

  def setup
    @user = User.find(2)
    @request.session[:user_id] = @user.id
    @project = Project.find(1)
    @block = 'my_resource_bookings'
    @block_id = Redmine::VERSION.to_s < '3.4' ? '#block_my-resource-bookings' : '#block-my_resource_bookings'

    EnabledModule.create(project: @project, name: 'resources')
  end

  def test_add_my_resource_bookings_block
    if Redmine::VERSION.to_s < '3.4'
      compatible_request :post, :add_block, block: @block
      assert_redirected_to '/my/page_layout'
    else
      compatible_xhr_request :post, :add_block, block: @block
      assert_response :success
    end

    assert_include @block, @user.pref[:my_page_layout]['top']
  end

  def test_remove_my_resource_bookings_block
    init_preferences

    if Redmine::VERSION.to_s < '3.4'
      compatible_request :post, :remove_block, block:  @block
      assert_redirected_to '/my/page_layout'
    else
      compatible_xhr_request :post, :remove_block, block: @block
      assert_response :success
      assert_include '$("#block-my_resource_bookings").remove();', response.body
    end

    @preferences.reload
    assert !@preferences[:my_page_layout].values.flatten.include?(@block)
  end

  def test_page_with_my_resource_bookings_block_and_no_custom_settings_and_no_bookings
    init_preferences

    travel_to Date.new(2018, 1, 1) do
      compatible_request :get, :page
      assert_select '.mypage-box' do
        check_settings show_weekends: 1, show_project_names: 1, show_spent_time: 1
        assert_select 'div.my-resource-bookings-chart', 0
      end
    end
  end if Redmine::VERSION.to_s >= '3.0' # travel_to helper added in Rails  4.1

  def test_page_with_my_resource_bookings_block_and_no_custom_settings_and_existing_bookings
    init_preferences

    travel_to Date.new(2018, 12, 15) do
      compatible_request :get, :page
      assert_select '.mypage-box' do
        check_settings show_weekends: 1, show_project_names: 1, show_spent_time: 1
        assert_select 'div#my-resource-bookings-chart' do
          assert_select 'table > tbody > tr.booking-data'
        end
      end
    end
  end if Redmine::VERSION.to_s >= '3.0'

  def test_page_with_my_resource_bookings_block_and_custom_settings_and_existing_bookings
    init_preferences('my_resource_bookings' => { show_weekends: '0', show_project_names: '1', show_spent_time: '1' })

    travel_to Date.new(2018, 12, 15) do
      compatible_request :get, :page
      assert_select '.mypage-box' do
        check_settings show_weekends: 0, show_project_names: 1, show_spent_time: 1
        assert_select 'div#my-resource-bookings-chart' do
          assert_select 'table > tbody > tr.booking-data'
        end
      end
    end
  end if Redmine::VERSION.to_s >= '3.0'

  def test_update_page_with_my_resource_bookings_block
    init_preferences

    settings = {
      my_resource_bookings: {
        'show_weekends' => '0',
        'show_project_names' => '0',
        'show_spent_time' => '1'
      }
    }

    compatible_xhr_request :post, :update_page, settings: { 'my_resource_bookings' => settings}
    assert_response :success
    assert_include '$("#block-my_resource_bookings").replaceWith(', response.body
    assert_equal settings, @user.reload.pref.my_page_settings('my_resource_bookings')
  end if Redmine::VERSION.to_s >= '3.4'

  private

  def init_preferences(my_page_settings = nil)
    @preferences = @user.pref
    @preferences[:my_page_layout] = { 'top' => ['my_resource_bookings'] }
    @preferences[:my_page_settings]= my_page_settings
    @preferences.save!
  end

  def check_settings(options = {})
    if Redmine::VERSION.to_s < '3.4'
      assert_select '#my_resource_bookings-settings', 0
    else
      assert_select '#my_resource_bookings-settings' do
        assert_select "#settings_my_resource_bookings_show_weekends[checked='checked']", options[:show_weekends]
        assert_select "#settings_my_resource_bookings_show_project_names[checked='checked']", options[:show_project_names]
        assert_select "#settings_my_resource_bookings_show_spent_time[checked='checked']", options[:show_spent_time]
      end
    end
  end
end
