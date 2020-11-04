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

class OperationCategoriesControllerTest < ActionController::TestCase
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
    @request.session[:user_id] = 1
    Project.find(1).enable_module!(:finance)
  end

  def test_should_get_new
    compatible_request :get, :new
    assert_response :success
    assert_select 'h2', /New operation category/
  end

  def test_should_get_edit
    compatible_request :get, :edit, :id => 1
    assert_response :success
    assert_select 'h2', /#{OperationCategory.find(1).name}/
  end

  def test_should_put_update
    compatible_request :put, :update, :id => 1, :operation_category => { :name => 'Changed category name' }
    assert_response :redirect
    assert_equal 'Changed category name', OperationCategory.find(1).name
  end

  def test_should_post_create
    compatible_request :post, :create, :operation_category => { :name => 'New category name',
                                                                :code => 'test_code',
                                                                :parent_id => nil }
    assert_response :redirect
    assert_equal 'New category name', OperationCategory.last.name
    assert_equal 'test_code', OperationCategory.last.code
  end

  def test_destroy_category_not_in_use
    new_category = OperationCategory.create(:name => 'Destroyable')
    assert_difference 'OperationCategory.count', -1 do
      compatible_request :delete, :destroy, :id => new_category.id
    end
    assert_redirected_to '/settings/plugin/redmine_finance?tab=operation_categories'
  end

  def test_destroy_category_in_use
    assert_not_nil Operation.where(:category_id => 1)
    assert_nil Operation.where(:category_id => 3).first

    compatible_request :delete, :destroy, :id => '1', :todo => 'reassign', :reassign_to_id => 3

    assert_nil OperationCategory.where(:id => 1).first
    assert_not_nil Operation.where(:category_id => 3)
    assert_nil Operation.where(:category_id => 1).first
    assert_redirected_to '/settings/plugin/redmine_finance?tab=operation_categories'
  end
end
