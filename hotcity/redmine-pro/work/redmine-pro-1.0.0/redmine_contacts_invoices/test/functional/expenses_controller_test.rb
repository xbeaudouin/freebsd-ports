# encoding: utf-8
#
# This file is a part of Redmine Invoices (redmine_contacts_invoices) plugin,
# invoicing plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# https://www.redmineup.com/
#
# redmine_contacts_invoices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts_invoices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts_invoices.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class ExpensesControllerTest < ActionController::TestCase
  include RedmineContacts::TestHelper
  include RedmineInvoices::TestHelper

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

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings])

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:invoices,
                                                                                                                             :invoice_lines,
                                                                                                                             :expenses])

  # TODO: Test for delete tags in update action

  def setup
    RedmineInvoices::TestCase.prepare

    User.current = nil
  end

  test 'should get index' do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    compatible_request :get, :index
    assert_response :success
    assert_not_nil expenses_in_list
  end

  test 'should get index in project' do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    compatible_request :get, :index, :project_id => 1
    assert_response :success
    assert_not_nil expenses_in_list
  end

  test 'should get index deny user in project' do
    @request.session[:user_id] = 4
    compatible_request :get, :index, :project_id => 1
    assert_response :forbidden
  end

  test 'should get index with filters' do
    @request.session[:user_id] = 1
    compatible_request :get, :index, :status_id => 1, :expenses_list_style => 'list_excerpt'
    assert_response :success
    assert_select 'div#contact_list td.name.expense-name a', '01/31/2012 - Hosting'
    assert_select 'div#contact_list td.name.expense-name a', :count => 0, :text => '1/002'
  end

  test 'should get index with sorting' do
    @request.session[:user_id] = 1
    compatible_request :get, :index, :status_id => 1,
                                     :sort => 'expense_date',
                                     :expenses_list_style => 'list_excerpt'
    assert_response :success
    assert_select 'div#contact_list td.name.expense-name a', '01/31/2012 - Hosting'
    assert_select 'div#contact_list td.name.expense-name a', :count => 0, :text => '1/002'
  end

  test 'should get index with grouping' do
    @request.session[:user_id] = 1
    compatible_request :get, :index, :status_id => 1,
                                     :group_by => 'assigned_to',
                                     :expenses_list_style => 'list_excerpt'
    assert_response :success
    assert_not_nil expenses_in_list
    assert_select 'div#contact_list tr.group'
  end

  test 'should get new' do
    @request.session[:user_id] = 2
    compatible_request :get, :new, :project_id => 1
    assert_response :success
    assert_select 'input#expense_price'
    assert_select 'input#expense_description'
  end

  test 'should not get new by deny user' do
    @request.session[:user_id] = 4
    compatible_request :get, :new, :project_id => 1
    assert_response :forbidden
  end

  test "should post create" do
    field = ExpenseCustomField.create!(:name => 'Test', :is_filter => true, :field_format => 'string')
    @request.session[:user_id] = 1
    assert_difference 'Expense.count' do
      compatible_request :post, :create, 'expense' => { 'price' => '140.0',
                                                        'description' => 'New expense',
                                                        'expense_date' => '2011-12-01',
                                                        'contact_id' => 2,
                                                        'status_id' => '1',
                                                        'custom_field_values' => { "#{field.id}" => 'expense one' } },
                                         'project_id' => 'ecookbook'
    end
    assert_redirected_to :controller => 'expenses', :action => 'index', :project_id => "ecookbook"

    expense = Expense.where(:description => 'New expense').first
    assert_not_nil expense
    assert_equal 'expense one', expense.custom_field_values.last.value
  end

  test 'should not post create by deny user' do
    @request.session[:user_id] = 4
    compatible_request :post, :create, :project_id => 1, :expense => { 'price' => '140.0' }
    assert_response :forbidden
  end

  test 'should get edit' do
    @request.session[:user_id] = 1
    compatible_request :get, :edit, :id => 1
    assert_response :success
    assert_select 'input#expense_price[value=?]', '19.99'
    assert_select 'input#expense_description[value=?]', 'Hosting'
  end

  test 'should put update' do
    @request.session[:user_id] = 1

    expense = Expense.find(1)
    new_price = 67.10

    compatible_request :put, :update, :id => 1, :expense => { :price => new_price }
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    expense.reload
    assert_equal new_price, expense.price.to_f
  end

  test 'should post destroy' do
    @request.session[:user_id] = 1
    compatible_request :delete, :destroy, :id => 1
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Expense.where(:id => 1).first
  end

  test 'should bulk_destroy' do
    @request.session[:user_id] = 1
    assert_not_nil Expense.find_by_id(1)
    compatible_request :delete, :bulk_destroy, :ids => [1]
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Expense.where(:id => 1).first
  end

  test 'should bulk_update' do
    @request.session[:user_id] = 1
    compatible_request :put, :bulk_update, :ids => [1, 2], :expense => { :status_id => 2 }
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert(Expense.where(:id => [1, 2]).all? { |e| e.status_id == 2 })
  end

  test 'should get context menu' do
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :context_menu, :back_url => '/projects/ecookbok/expenses',
                                                :project_id => 'ecookbook',
                                                :ids => ['1', '2']
    assert_response :success
  end

  test 'should get index as csv' do
    field = ExpenseCustomField.create!(:name => 'Test custom field', :is_filter => true, :field_format => 'string')
    expense = Expense.find(1)
    expense.custom_field_values = { field.id => 'This is custom значение' }
    expense.save

    @request.session[:user_id] = 1
    compatible_request :get, :index, :format => 'csv'
    assert_response :success
    assert_not_nil expenses_in_list
    assert_match 'text/csv', @response.content_type
    assert @response.body.starts_with?('#,')
  end

  test 'should have import CSV link for user authorized to' do
    @request.session[:user_id] = 1
    compatible_request :get, :index, :project_id => 1
    assert_response :success
    assert_select 'a#import_from_csv'
  end

  class ExpensesPermissionTest < ActionController::TestCase
    fixtures :projects, :users, :roles, :members, :member_roles

    def setup
      @project = Project.find(1)
      @user = User.find(2)
      @request.session[:user_id] = @user.id
      @project.enable_module! :contacts_expenses
      @controller = ExpensesController.new
    end

    def test_that_user_with_add_expenses_can_get_new
      @user.roles_for_project(@project).first.add_permission! :add_expenses
      compatible_request :get, :new, :project_id => @project.id
      assert_response :success
    end

    def test_that_edit_expenses_allows_to_get_new
      @user.roles_for_project(@project).first.add_permission! :edit_expenses
      compatible_request :get, :new, :project_id => @project.id
      assert_response :success
    end

    def test_that_edit_own_expenses_also_allows_to_get_new
      @user.roles_for_project(@project).first.add_permission! :edit_own_expenses
      compatible_request :get, :new, :project_id => @project.id
      assert_response :success
    end

    def test_that_user_with_add_expenses_can_post_on_create
      @user.roles_for_project(@project).first.add_permission! :add_expenses
      assert_difference 'Expense.count' do
        compatible_request :post, :create, :project_id => @project.id,
                                           :expense => {
                                             :price => '10.2',
                                             :expense_date => '2018-02-06'
                                           }
      end
      assert_redirected_to project_expenses_url(@project)
    end

    def test_that_edit_expenses_allows_post_on_create
      @user.roles_for_project(@project).first.add_permission! :edit_expenses
      assert_difference 'Expense.count' do
        compatible_request :post, :create, :project_id => @project.id,
                                           :expense => {
                                             :price => '10.2',
                                             :expense_date => '2018-02-06'
                                           }
      end
      assert_redirected_to project_expenses_url(@project)
    end

    def test_if_edit_own_expenses_also_allows_to_post_on_create
      @user.roles_for_project(@project).first.add_permission! :edit_own_expenses
      assert_difference 'Expense.count' do
        compatible_request :post, :create, :project_id => @project.id,
                                           :expense => {
                                             :price => '10.2',
                                             :expense_date => '2018-02-06'
                                           }
      end
      assert_redirected_to project_expenses_url(@project)
    end
  end
end
