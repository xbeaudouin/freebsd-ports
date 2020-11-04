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

class ExpensesTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles

  def setup
    @user = User.find(2)
    @project = Project.find(1)
    @project.enable_module! :contacts_expenses
  end

  def test_can_create_expenses_with_add_expenses
    @user.roles_for_project(@project).first.add_permission! :view_expenses
    @user.roles_for_project(@project).first.add_permission! :add_expenses
    log_user('jsmith', 'jsmith')

    compatible_request :get, project_expenses_path(@project)
    assert_response :success
    assert_select 'a[href^=?]', new_project_expense_path(@project)

    compatible_request :get, new_project_expense_path(@project)
    assert_response :success
    assert_select 'select[name=?]', 'expense[project_id]' do
      assert_select 'option', :text => @project.name
    end
    assert_select 'input[name=?]', 'expense[price]'
    assert_select 'input[name=?]', 'expense[expense_date]'

    compatible_request :post, project_expenses_path(@project),
                       :project_id => @project.id,
                       :expense => { :price => '12.3', :expense_date => '2018-02-16' }
    assert_redirected_to project_expenses_path(@project)
  end

  def test_can_create_expenses_with_edit_expenses
    @user.roles_for_project(@project).first.add_permission! :view_expenses
    @user.roles_for_project(@project).first.add_permission! :edit_expenses
    log_user('jsmith', 'jsmith')

    compatible_request :get, project_expenses_path(@project)
    assert_response :success
    assert_select 'a[href^=?]', new_project_expense_path(@project)

    compatible_request :get, new_project_expense_path(@project)
    assert_response :success
    assert_select 'select[name=?]', 'expense[project_id]' do
      assert_select 'option', :text => @project.name
    end
    assert_select 'input[name=?]', 'expense[price]'
    assert_select 'input[name=?]', 'expense[expense_date]'

    compatible_request :post, project_expenses_path(@project), :project_id => @project.id,
                                                               :expense => { :price => '12.3',
                                                                             :expense_date => '2018-02-16' }
    assert_redirected_to project_expenses_path(@project)
  end

  def test_can_create_expenses_with_edit_own_expenses
    @user.roles_for_project(@project).first.add_permission! :view_expenses
    @user.roles_for_project(@project).first.add_permission! :edit_own_expenses
    log_user('jsmith', 'jsmith')

    compatible_request :get, project_expenses_path(@project)
    assert_response :success
    assert_select 'a[href^=?]', new_project_expense_path(@project)

    compatible_request :get, new_project_expense_path(@project)
    assert_response :success
    assert_select 'select[name=?]', 'expense[project_id]' do
      assert_select 'option', :text => @project.name
    end
    assert_select 'input[name=?]', 'expense[price]'
    assert_select 'input[name=?]', 'expense[expense_date]'

    compatible_request :post, project_expenses_path(@project), :project_id => @project.id,
                                                               :expense => { :price => '12.3',
                                                                             :expense_date => '2018-02-16' }
    assert_redirected_to project_expenses_path(@project)
  end

  def test_new_expense_link_is_visible_without_project_context
    @user.roles_for_project(@project).first.add_permission! :view_expenses
    @user.roles_for_project(@project).first.add_permission! :add_expenses
    log_user('jsmith', 'jsmith')

    compatible_request :get, expenses_path
    assert_response :success
    assert_select 'a[href^=?]', new_project_expense_path(@project)
  end

  def test_new_expense_link_is_invisible_in_other_project_context
    @other_project = Project.find(2)
    @other_project.enable_module! :contacts_expenses
    @user.roles_for_project(@other_project).first.add_permission! :view_expenses
    @user.roles_for_project(@other_project).first.add_permission! :add_expenses
    @user.roles_for_project(@project).first.add_permission! :view_expenses
    log_user('jsmith', 'jsmith')

    compatible_request :get, project_expenses_path(@project)
    assert_response :success
    assert_select 'a[href^=?]', new_project_expense_path(@project), false
  end
end
