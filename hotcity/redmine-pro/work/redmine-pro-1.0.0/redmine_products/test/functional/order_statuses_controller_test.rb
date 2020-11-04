# encoding: utf-8
#
# This file is a part of Redmine Products (redmine_products) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_products is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_products is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_products.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class OrderStatusesControllerTest < ActionController::TestCase
  include RedmineContacts::TestHelper

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

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects])

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/', [:products,
                                                                                                                    :order_statuses,
                                                                                                                    :orders,
                                                                                                                    :product_lines])

  def test_index_by_anonymous_should_redirect_to_login_form
    @request.session[:user_id] = nil
    compatible_request :get, :index
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Forder_statuses'
  end

  def test_should_get_new
    @request.session[:user_id] = 1
    compatible_request :get, :new
    assert_response :success
  end

  def test_should_create
    @request.session[:user_id] = 1
    assert_difference 'OrderStatus.count', 1 do
      compatible_request :post, :create, :order_status => { :name => 'test', 'color_name' => '#ffffff',
                                                            :status_type => OrderStatus::ORDER_STATUS_TYPE_COMPLETED, :is_default => '1' }
      assert_redirected_to :controller => 'settings', :action => 'plugin',
                           :id => 'redmine_products', :tab => 'order_statuses'
    end
  end

  def test_get_edit
    @request.session[:user_id] = 1
    compatible_request :get, :edit, :id => 1
    assert_response :success
  end

  def test_put_update
    @request.session[:user_id] = 1
    status1 = OrderStatus.find(1)
    new_name = 'updated main'
    if Redmine::VERSION.to_s < '3.0'
      compatible_request :put, :update, :id => 1, :order_status => { :name => new_name, :color_name => '#000000' }
    else
      compatible_request :patch, :update, :id => 1, :order_status => { :name => new_name, :color_name => '#000000' }
    end
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => 'redmine_products', :tab => 'order_statuses'
    status1.reload
    assert_equal new_name, status1.name
  end

  def test_sort_update
    @request.session[:user_id] = 1
    second_status = OrderStatus.where(:position => 2).first
    thried_status = OrderStatus.where(:position => 3).first
    if Redmine::VERSION.to_s >= '3.3'
      compatible_request :put, :update, :id => second_status.id, :order_status => { :position => '3' }
    else
      compatible_request :put, :update, :id => second_status.id, :order_status => { :move_to => 'lower' }
    end
    second_status.reload
    thried_status.reload
    assert_equal 3, second_status.position
    assert_equal 2, thried_status.position
  end

  def test_destroy
    @request.session[:user_id] = 1
    Order.where('status_id = 1').delete_all

    assert_difference 'OrderStatus.count', -1 do
      compatible_request :delete, :destroy, :id => '1'
    end
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => 'redmine_products', :tab => 'order_statuses'
    assert_nil OrderStatus.where(:id => 1).first
  end
end
