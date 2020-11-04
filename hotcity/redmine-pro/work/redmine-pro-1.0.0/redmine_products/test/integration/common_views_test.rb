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

class CommonViewsTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
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
                                                                                                                    :product_categories,
                                                                                                                    :product_lines])

  def setup
    RedmineProducts::TestCase.prepare
  end
  def test_new_custom_field
    log_user('admin', 'admin')
    compatible_request :get, '/custom_fields/new', :type => 'ProductLineCustomField'
    assert_response :success
    assert_select '#custom_field_field_format>option', Redmine::VERSION.to_s < '2.5' ? 5 : 6
    assert_select '#custom_field_field_format>option', 'Boolean'
    assert_select '#custom_field_field_format>option', 'Date'
    assert_select '#custom_field_field_format>option', 'Float'
    assert_select '#custom_field_field_format>option', 'Integer'
    assert_select '#custom_field_field_format>option', 'Text'
    assert_select '#custom_field_field_format>option', 'Link' if Redmine::VERSION.to_s >= '2.5'
  end
end
