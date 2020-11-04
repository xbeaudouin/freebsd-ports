# encoding: utf-8
#
# This file is a part of Redmine Finance (redmine_finance) plugin,
# simple accounting plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_finance is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_finance is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_finance.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class OperationsControllerTest < ActionController::TestCase
  include RedmineContacts::TestHelper
  include RedmineFinance::TestCase::TestHelper

  fixtures :projects,
           :users,
           :user_preferences,
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

  RedmineFinance::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                   :contacts_projects,
                                                                                                                   :contacts_issues,
                                                                                                                   :deals,
                                                                                                                   :notes,
                                                                                                                   :tags,
                                                                                                                   :taggings,
                                                                                                                   :queries])
  if RedmineFinance.invoices_plugin_installed?
    RedmineFinance::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:invoices,
                                                                                                                              :invoice_lines])
  end

  RedmineFinance::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_finance).directory + '/test/fixtures/', [:accounts,
                                                                                                                  :operations,
                                                                                                                  :operation_categories])

  def setup
    Setting.plugin_redmine_finance['finance_operations_approval'] = 0
    Project.find(1).enable_module!(:finance)
  end

  def test_should_get_index
    @request.session[:user_id] = 1
    compatible_request :get, :index
    assert_response :success
    assert_not_nil operations_in_list
  end

  def test_should_get_show
    @request.session[:user_id] = 1
    compatible_request :get, :show, :id => 1
    assert_response :success
    assert_select 'h2', 'Operation #1'
  end

  def test_should_get_new
    @request.session[:user_id] = 1
    compatible_request :get, :new, :project_id => 1
    assert_response :success
    assert_select 'h2', 'New operation'
  end

  def test_should_get_edit
    @request.session[:user_id] = 1
    compatible_request :get, :edit, :id => 1
    assert_response :success
    assert_select 'h2', 'Edit operation'
  end

  def test_should_put_update
    @request.session[:user_id] = 1
    compatible_request :put, :update, :id => 1, :operation => { :amount => 99.9 }
    assert_response :redirect
    assert_equal 99.9, Operation.find(1).amount.to_f
  end

  def test_destroy
    @request.session[:user_id] = 1
    compatible_request :delete, :destroy, :id => 1
    assert_redirected_to '/projects/ecookbook/operations'
    assert_nil Operation.where(:id => 1).first
  end

  def test_should_post_create
    @request.session[:user_id] = 1
    assert_difference 'Operation.count' do
      compatible_request :post, :create, :project_id => 1,
                                         :operation => { :description => 'New operation description',
                                                         :account_id => 1,
                                                         :amount => 1000,
                                                         :category_id => 1,
                                                         :operation_date => Time.now }
      assert_response :redirect
    end
    assert_equal 1030, Operation.last.account.amount
    assert_equal 'New operation description', Operation.last.description
  end

  def test_should_post_create_for_user_negative_timezone
    user = User.find(1)
    current_time_zone = user.preference.time_zone
    user.preference.update_attributes(:time_zone => 'Brasilia')
    @request.session[:user_id] = 1
    assert_difference 'Operation.count' do
      compatible_request :post, :create, :project_id => 1, :operation => { :description => 'New operation description',
                                                                           :account_id => 1,
                                                                           :amount => 1000,
                                                                           :category_id => 1,
                                                                           :operation_date => '2017-04-20' },
                                                           :operation_time => '11:11'
      assert_response :redirect
    end
    assert_equal '2017-04-20 11:11:00 -0300', Operation.last.operation_date.to_s
  ensure
    user.preference.update_attributes(:time_zone => current_time_zone)
  end
  def test_should_post_create_approved
    @request.session[:user_id] = 1
    compatible_request :post, :create, :project_id => 1, :operation => { :description => 'New approved operation description',
                                                                         :account_id => 1,
                                                                         :amount => 1234,
                                                                         :category_id => 1,
                                                                         :operation_date => Time.now,
                                                                         :is_approved => true }
    assert_response :redirect
    assert Operation.order(:id).last.is_approved?
  end

  def test_should_get_index_as_csv
    field = OperationCustomField.create!(:name => 'Test custom field', :is_filter => true, :field_format => 'string')
    operation = Operation.find(1)
    operation.custom_field_values = { field.id => 'This is custom значение' }
    operation.save

    @request.session[:user_id] = 1
    compatible_request :get, :index, :format => 'csv'
    assert_not_nil operations_in_list
    assert @response.body.starts_with?('#,')
  end

  def test_get_index_calendar
    @request.session[:user_id] = 1

    compatible_request :get, :index, :operations_list_style => 'crm_calendars/crm_calendar'
    assert_response :success
    assert_select 'td.even div.operation a', /120/
  end

  def test_get_index_with_approvals
    @request.session[:user_id] = 1
    Setting.plugin_redmine_finance['finance_operations_approval'] = 1
    compatible_request :get, :index, :project_id => 'ecookbook'
    assert_response :success
    assert_select '.accounts-stat tr.disapproved.expense' do
      assert_select 'th a', :text => 'Disapproved expense'
      assert_select 'td.sum', /20\.0/
    end
  end

  def test_xhr_get_context_menu
    @request.session[:user_id] = 1
    Setting.plugin_redmine_finance['finance_operations_approval'] = 1
    compatible_xhr_request :get, :context_menu, :ids => ['3', '4']
    assert_response :success
    assert_match /(Approve|Disapprove)/, @response.body
  end

  def test_post_bulk_update
    @request.session[:user_id] = 1
    Setting.plugin_redmine_finance['finance_operations_approval'] = 1
    compatible_request :post, :bulk_update, :ids => ['2', '4'], :operation => { 'is_approved' => 'false' }
    assert Operation.find(2, 4).map { |operation| !operation.is_approved? }.all?
  end

  def test_filter_by_ids
    @request.session[:user_id] = 1
    ids = [3, 2]
    compatible_request :get, :index, :project_id => 1, :set_filter => 1, 'f' => ['ids', ''], 'op' => { 'ids' => '=' }, 'v' => { 'ids' => [ids.join(',')] }
    assert_equal ids.sort, operations_in_list.map(&:id).sort
  end if Redmine::VERSION.to_s >= '3.3'

  def test_should_filter_operation_by_currency
    @request.session[:user_id] = 1
    compatible_request :get, :index, :set_filter => 1, :object_type => 'operation', :f => ['currency'], :op => { 'currency' => '=' }, :v => { 'currency' => ['EUR'] }
    assert_response :success
    assert_equal Account.where(:currency => 'EUR').first.operations, operations_in_list
  end

  def test_should_filter_operation_by_project
    @request.session[:user_id] = 1
    compatible_request :get, :index, set_filter: 1, object_type: 'operation', f: ['project_id'], :op => { 'project_id' => '=' }, :v => { "project_id" => ["1"] }
    assert_response :success
    assert_equal Account.where(:project_id => 1).map(&:operations).flatten.sort, operations_in_list.sort
  end

  def test_should_get_index_with_saved_query
    Setting.plugin_redmine_finance['finance_operations_approval'] = 1
    operation_query = OperationQuery.create(:name => 'Test', :filters => { 'is_approved' => { :operator => '=', :values => ['1'] } }, 'user_id' => 1, 'column_names' => [:id])
    @request.session[:user_id] = 1
    compatible_request :get, :index, :query_id => operation_query.id, :project_id => Project.find(1).identifier
    assert_response :success
    assert_not_nil operations_in_list
  end
end
