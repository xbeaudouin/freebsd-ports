# encoding: utf-8
#
# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class IssuesControllerTest < ActionController::TestCase
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

  RedmineContacts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  def setup
    RedmineContacts::TestCase.prepare
    User.current = nil
    @request.session[:user_id] = 1

    issue = Issue.find(1)
    contact = Contact.find(2)
    deal = Deal.find(1)
    @contact_cf = IssueCustomField.create!(name: 'Related contacts',
                                           field_format: 'contact',
                                           is_filter: true,
                                           is_for_all: true,
                                           multiple: true,
                                           tracker_ids: Tracker.pluck(:id))
    @deal_cf = IssueCustomField.create!(name: 'Related deals',
                                        field_format: 'deal',
                                        is_filter: true,
                                        is_for_all: true,
                                        multiple: true,
                                        tracker_ids: Tracker.pluck(:id))

    CustomValue.create!(custom_field: @contact_cf, customized: issue, value: contact.id)
    CustomValue.create!(custom_field: @deal_cf, customized: issue, value: deal.id)
  end
  def test_get_index_with_contacts_and_deals
    compatible_request :get, :index, :f => ['status_id', "cf_#{@contact_cf.id}", ''],
                                     :op => { :status_id => 'o', "cf_#{@contact_cf.id}" => '=' },
                                     :v => { "cf_#{@contact_cf.id}" => ['2'] },
                                     :c => ['subject', "cf_#{@contact_cf.id}", "cf_#{@deal_cf.id}"],
                                     :project_id => 'ecookbook'
    assert_response :success
    assert_select 'table.list.issues td.contact span.contact a', /Marat Aminov/
    assert_select 'table.list.issues td.deal a', /First deal with contacts/
  end

  def test_get_issues_without_contacts
    compatible_request :get, :index, :f => ['status_id', "cf_#{@contact_cf.id}", ''],
                                     :op => { :status_id => '*', "cf_#{@contact_cf.id}" => '!*' },
                                     :c => ['subject', "cf_#{@contact_cf.id}"],
                                     :project_id => 'ecookbook'
    assert_response :success
    assert_select 'table.list.issues td.contact', ''
  end

  def test_get_issues_only_with_contacts
    compatible_request :get, :index, :f => ['status_id', "cf_#{@contact_cf.id}", ''],
                                     :op => { :status_id => '*', "cf_#{@contact_cf.id}" => '*' },
                                     :c => ['subject', "cf_#{@contact_cf.id}"],
                                     :project_id => 'ecookbook'
    assert_response :success
    assert_select 'table.list.issues td.contact'
  end
end
