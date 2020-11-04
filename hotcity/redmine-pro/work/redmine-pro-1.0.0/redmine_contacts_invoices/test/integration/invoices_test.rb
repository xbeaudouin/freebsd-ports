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

class InvoicesTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles

  def setup
    @user = User.find(2)
    @project = Project.find(1)
    @project.enable_module! :contacts_invoices
  end

  def test_can_create_invoices_with_add_invoices
    @user.roles_for_project(@project).first.add_permission! :view_invoices
    @user.roles_for_project(@project).first.add_permission! :add_invoices
    log_user('jsmith', 'jsmith')

    compatible_request :get, project_invoices_path(@project)
    assert_response :success
    assert_select 'a[href^=?]', new_project_invoice_path(@project)

    compatible_request :get, new_project_invoice_path(@project)
    assert_response :success
    assert_select 'input[name=?]', 'invoice[number]'
    assert_select 'select[name=?]', 'invoice[project_id]' do
      assert_select 'option', :text => @project.name
    end
    assert_select 'select[name=?]', 'invoice[status_id]' do
      assert_select 'option', :value => 1
    end
    assert_select 'input[name=?]', 'invoice[invoice_date]'

    compatible_request :post, project_invoices_path(@project),
                       :project_id => @project.id,
                       :invoice => {
                         :number => '1/123',
                         :status_id => 1,
                         :invoice_date => '2018-02-16'
                       }
    assert_redirected_to invoice_url(Invoice.last)
  end

  def test_can_create_invoices_with_edit_invoices
    @user.roles_for_project(@project).first.add_permission! :view_invoices
    @user.roles_for_project(@project).first.add_permission! :edit_invoices
    log_user('jsmith', 'jsmith')

    compatible_request :get, project_invoices_path(@project)
    assert_response :success
    assert_select 'a[href^=?]', new_project_invoice_path(@project)

    compatible_request :get, new_project_invoice_path(@project)
    assert_response :success
    assert_select 'input[name=?]', 'invoice[number]'
    assert_select 'select[name=?]', 'invoice[project_id]' do
      assert_select 'option', :text => @project.name
    end
    assert_select 'select[name=?]', 'invoice[status_id]' do
      assert_select 'option', :value => 1
    end
    assert_select 'input[name=?]', 'invoice[invoice_date]'

    compatible_request :post, project_invoices_path(@project),
         :project_id => @project.id,
         :invoice => {
           :number => '1/123',
           :status_id => 1,
           :invoice_date => '2018-02-16'
         }
    assert_redirected_to invoice_url(Invoice.last)
  end

  def test_can_create_invoices_with_edit_own_invoices
    @user.roles_for_project(@project).first.add_permission! :view_invoices
    @user.roles_for_project(@project).first.add_permission! :edit_own_invoices
    log_user('jsmith', 'jsmith')

    compatible_request :get, project_invoices_path(@project)
    assert_response :success
    assert_select 'a[href^=?]', new_project_invoice_path(@project)

    compatible_request :get, new_project_invoice_path(@project)
    assert_response :success
    assert_select 'input[name=?]', 'invoice[number]'
    assert_select 'select[name=?]', 'invoice[project_id]' do
      assert_select 'option', :text => @project.name
    end
    assert_select 'select[name=?]', 'invoice[status_id]' do
      assert_select 'option', :value => 1
    end
    assert_select 'input[name=?]', 'invoice[invoice_date]'

    compatible_request :post, project_invoices_path(@project),
         :project_id => @project.id,
         :invoice => {
           :number => '1/123',
           :status_id => 1,
           :invoice_date => '2018-02-16'
         }
    assert_redirected_to invoice_url(Invoice.last)
  end

  def test_new_invoice_link_is_visible_without_project_context
    @user.roles_for_project(@project).first.add_permission! :view_invoices
    @user.roles_for_project(@project).first.add_permission! :add_invoices
    log_user('jsmith', 'jsmith')

    compatible_request :get, invoices_path
    assert_response :success
    assert_select 'a[href^=?]', new_project_invoice_path(@project)
  end

  def test_new_invoice_link_is_invisible_in_other_project_context
    @other_project = Project.find(2)
    @other_project.enable_module! :contacts_invoices
    @user.roles_for_project(@other_project).first.add_permission! :view_invoices
    @user.roles_for_project(@other_project).first.add_permission! :add_invoices
    @user.roles_for_project(@project).first.add_permission! :view_invoices
    log_user('jsmith', 'jsmith')

    compatible_request :get, project_invoices_path(@project)
    assert_response :success
    assert_select 'a[href^=?]', new_project_invoice_path(@project), false
  end
end
