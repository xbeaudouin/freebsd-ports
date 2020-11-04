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

class InvoiceTemplatesControllerTest < ActionController::TestCase
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
                                                                                                                    :taggings,
                                                                                                                    :queries])

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:invoices,
                                                                                                                             :invoice_lines,
                                                                                                                             :invoice_templates])

  def setup
    RedmineInvoices::TestCase.prepare
    @request.session[:user_id] = 1
    @stub_settings = { 'invoices_company_name' => 'Your company name',
                       'invoices_company_representative' => 'Company representative name',
                       'invoices_template' => 'classic',
                       'invoices_cross_project_contacts' => 1,
                       'invoices_number_format' => '#INV/%%YEAR%%%%MONTH%%%%DAY%%-%%ID%%',
                       'invoices_company_info' => "Your company address\nTax ID\nphone:\nfax:",
                       'invoices_company_logo_url' => "http://www.redmine.org/attachments/3458/redmine_logo_v1.png",
                       'invoices_bill_info' => 'Your billing information (Bank, Address, IBAN, SWIFT & etc.)',
                       'invoices_units' => "hours\ndays\nservice\nproducts",
                       'per_invoice_templates' => 1 }
  end

  def test_should_get_new
    with_invoice_settings @stub_settings do
      compatible_request :get, :new, :project_id => 1
      assert_response 200
    end
  end

  def test_should_get_edit
    with_invoice_settings @stub_settings do
      compatible_request :get, :edit, :id => 1
      assert_response 200
    end
  end

  def test_should_post_create
    with_invoice_settings @stub_settings do
      compatible_request :post, :create, :invoice_template => { :name => 'New invoice template',
                                                                :content => 'Hi there!' },
                                         :project_id => 1
      assert_redirected_to settings_project_path(Project.find('ecookbook'), :tab => 'invoice_templates')
      assert_equal 'New invoice template', InvoiceTemplate.last.name
    end
  end

  def test_should_put_update
    with_invoice_settings @stub_settings do
      compatible_request :put, :update, :id => 1, :invoice_template => { :name => 'New name' }
      assert_redirected_to settings_project_path(Project.find('ecookbook'), :tab => 'invoice_templates')
      assert_equal 'New name', InvoiceTemplate.find(1).name
    end
  end

  def test_should_delete_destroy
    with_invoice_settings @stub_settings do
      compatible_request :delete, :destroy, :id => 1
      assert_redirected_to settings_project_path(Project.find('ecookbook'), :tab => 'invoice_templates')
      assert_nil InvoiceTemplate.where(:id => 1).first
    end
  end

  def test_get_preview
    with_invoice_settings @stub_settings do
      compatible_request :get, :preview, :id => 1
      assert_response 200
    end
  end

  def test_should_get_index
    with_invoice_settings @stub_settings do
      compatible_request :get, :index, :project_id => 1
      assert_response 200
    end
  end
end
