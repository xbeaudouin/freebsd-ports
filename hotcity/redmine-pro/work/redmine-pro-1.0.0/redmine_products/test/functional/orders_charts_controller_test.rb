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

class OrdersChartsControllerTest < ActionController::TestCase
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

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/',
                                        [:invoices,
                                          :invoice_lines]) if ProductsSettings.invoices_plugin_installed?

  def setup
    RedmineProducts::TestCase.prepare
    Project.find(1).enabled_module_names = [:orders]
    Role.find(1).add_permission! :view_charts
  end

  def test_charts_by_anonymous_should_redirect_to_login
    @request.session[:user_id] = nil
    compatible_request :get, :show, project_id: 1
    assert_response :redirect
  end

  def test_should_get_charts
    @request.session[:user_id] = 1
    compatible_request :get, :show, project_id: 1
    assert_response :success
  end

  def test_show_chart_with_interval_size
    @request.session[:user_id] = 1
    compatible_request :get, :show, chart: 'total_sales', interval_size: 'week'
    assert_response :success
  end

  def test_show_chart_without_interval_size
    @request.session[:user_id] = 1
    compatible_request :get, :show, chart: 'total_sales'
    assert_response :success
  end

  def test_show_chart_without_interval_size_after_reset
    @request.session[:user_id] = 1
    compatible_request :get, :show, set_filter: 1
    compatible_request :get, :show, chart: 'total_sales'
    assert_response :success
  end

  def test_get_render_data_number_of_orders
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :render_chart, chart: 'number_of_orders', project_id: 1, interval_size: 'year'
    assert_response :success
    assert_equal 'application/json', @response.content_type
  end

  def test_get_render_data_total_sales
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :render_chart, chart: 'total_sales', project_id: 1, interval_size: 'year'
    assert_response :success
    assert_equal 'application/json', @response.content_type
  end

  def test_get_render_data_aov
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :render_chart, chart: 'average_order_value', project_id: 1, interval_size: 'year'
    assert_response :success
    assert_equal 'application/json', @response.content_type
  end

  def test_get_render_data_popular_products
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :render_chart, chart: 'popular_products', project_id: 1
    assert_response :success
    assert_equal 'application/json', @response.content_type
  end

  def test_get_render_data_popular_categories
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :render_chart, chart: 'popular_categories', project_id: 1
    assert_response :success
    assert_equal 'application/json', @response.content_type
  end
end
