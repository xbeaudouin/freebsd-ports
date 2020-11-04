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

class ExpenseTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles
  def test_set_price
    expense = Expense.new(:price => '1 000')
    assert_equal 1000.0, expense.price
  end

  def test_exprense_creation
    expense = Expense.new(:status_id => 1,
                          :contact_id => 1,
                          :project_id => 2,
                          :price => '555',
                          :currency => 'USD',
                          :expense_date => '2015-07-28',
                          :assigned_to_id => 1,
                          :is_billable => true,
                          :description => 'test desc')
    expense.save
    assert_equal false, expense.new_record?
    assert_equal expense.is_billable, true
    assert_equal expense.description, 'test desc'
    assert_equal expense.project_id, 2
    assert_equal expense.assigned_to_id, 1
  end

  def test_allowed_projects_returns_projects_with_add_expenses
    project = Project.find(1)
    project.enable_module!(:contacts_expenses)

    user = User.find(2)
    user.roles_for_project(project).first.add_permission!(:add_expenses)

    allowed_projects = Expense.allowed_target_projects(user)

    assert_include project, allowed_projects
    assert_equal 1, allowed_projects.count
  end

  def test_allowed_projects_returns_projects_with_edit_expenses
    project = Project.find(1)
    project.enable_module!(:contacts_expenses)

    user = User.find(2)
    user.roles_for_project(project).first.add_permission!(:edit_expenses)

    allowed_projects = Expense.allowed_target_projects(user)

    assert_include project, allowed_projects
    assert_equal 1, allowed_projects.count
  end
end
