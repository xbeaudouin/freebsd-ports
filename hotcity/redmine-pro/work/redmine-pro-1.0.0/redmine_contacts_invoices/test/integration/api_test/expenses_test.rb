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

require File.expand_path('../../../test_helper', __FILE__)
# require File.dirname(__FILE__) + '/../../../../../test/test_helper'

class Redmine::ApiTest::ExpensesTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
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

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:expenses])

  def setup
    Setting.rest_api_enabled = '1'
    RedmineInvoices::TestCase.prepare
  end

  def test_get_expenses_xml
    compatible_api_request :get, '/expenses.xml', {}, credentials('admin')

    assert_select 'expenses', :attributes => { :type => 'array',
                                               :total_count => Expense.count,
                                               :limit => 25,
                                               :offset => 0 }
    assert_select 'expense', :child => { :tag => 'id', :content => Expense.first.id.to_s }
  end

  def test_post_expenses_xml
    assert_difference('Expense.count') do
      compatible_api_request :post, '/expenses.xml', { :expense => { :project_id => 1,
                                                                     :contact_id => 1,
                                                                     :status_id => 1,
                                                                     :expense_date => Date.today } },
                                                     credentials('admin')
    end

    expense = Expense.order('id DESC').first

    assert_response :created
    assert_equal 'application/xml', @response.content_type
    assert_select 'expense', :child => { :tag => 'id', :content => expense.id.to_s }
  end

  # Issue 6 is on a private project
  def test_put_expenses_1_xml
    @parameters = { :expense => { :description => 'NewDescription' } }
    if ActiveRecord::VERSION::MAJOR < 4
      Redmine::ApiTest::Base.should_allow_api_authentication(:put, '/expenses/1.xml', { :expense => { :description => 'NewDescription' } },
                                                                                      { :success_code => :ok })
    end

    assert_no_difference('Expense.count') do
      compatible_api_request :put, '/expenses/1.xml', @parameters, credentials('admin')
    end

    expense = Expense.find(1)
    assert_equal 'NewDescription', expense.description
  end
end
