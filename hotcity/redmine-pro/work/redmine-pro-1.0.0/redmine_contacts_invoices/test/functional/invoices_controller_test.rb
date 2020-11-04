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

class InvoicesControllerTest < ActionController::TestCase
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
                                                                                                                             :invoice_lines])
  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:invoice_templates])

  # TODO: Test for delete tags in update action

  def setup
    RedmineInvoices::TestCase.prepare
    Project.find(1).enable_module!(:contacts_invoices)
    User.current = nil
  end

  test 'should get index' do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    compatible_request :get, :index
    assert_response :success
    assert_not_nil invoices_in_list
  end

  def should_get_json
    Setting.rest_api_enabled = '1'
    @user = User.where(:login => 'admin').firs
    @request.env['HTTP_AUTHORIZATION'] = credentials('admin')

    compatible_request :get, :index, :format => 'json', :status_id => '*'
    assert_response :success
    assert_not_nil invoices_in_list
    parsed_response = JSON.parse(@response.body)
    assert_equal parsed_response['invoices'].count, 6
  ensure
    Setting.rest_api_enabled = '0'
  end

  def should_get_json_with_filter
    @user = User.where(:login => 'admin').first
    @request.env['HTTP_AUTHORIZATION'] = credentials('admin')

    compatible_request :get, :index, :format => 'json', :status_id => '3'
    assert_response :success
    assert_not_nil invoices_in_list
    parsed_response = JSON.parse(@response.body)
    assert_equal parsed_response['invoices'].count, 1
  ensure
    Setting.rest_api_enabled = '0'
  end

  def test_get_index_with_sorting
    @request.session[:user_id] = 1
    RedmineInvoices.settings['invoices_excerpt_invoice_list'] = 1
    compatible_request :get, :index, :sort => 'invoices.number:desc'
    assert_response :success
  end
  def test_get_index_calendar
    @request.session[:user_id] = 1
    compatible_request :get, :index, :invoices_list_style => 'crm_calendars/crm_calendar'
    assert_response :success
    assert_not_nil invoices_in_list
    assert_select 'td.even div.invoice a', '1/001'
  end

  test 'should get index in project' do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    compatible_request :get, :index, :project_id => 1
    assert_response :success
    assert_not_nil invoices_in_list
  end

  test 'should get index deny user in project' do
    @request.session[:user_id] = 4
    compatible_request :get, :index, :project_id => 1
    assert_response :forbidden
  end

  test 'should get index with empty settings' do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'
    with_invoice_settings({}) do
      compatible_request :get, :index
      assert_response :success
    end
  end

  def test_index_with_short_filters
    @request.session[:user_id] = 1
    to_test = {
      'status_id' => {
        'o' => { :op => 'o', :values => [''] },
        'c' => { :op => 'c', :values => [''] },
        '1' => { :op => '=', :values => ['1'] },
        '1|3|2' => { :op => '=', :values => ['1', '3', '2'] },
        '=1' => { :op => '=', :values => ['1'] },
        '!3' => { :op => '!', :values => ['3'] },
        '!1|3|2' => { :op => '!', :values => ['1', '3', '2'] } },
      'invoice_date' => {
        '2011-10-12' => { :op => '=', :values => ['2011-10-12'] },
        '=2011-10-12' => { :op => '=', :values => ['2011-10-12'] },
        '>=2011-10-12' => { :op => '>=', :values => ['2011-10-12'] },
        '<=2011-10-12' => { :op => '<=', :values => ['2011-10-12'] },
        '><2011-10-01|2011-10-30' => { :op => '><', :values => ['2011-10-01', '2011-10-30'] },
        '<t+2' => { :op => '<t+', :values => ['2'] },
        '>t+2' => { :op => '>t+', :values => ['2'] },
        't+2' => { :op => 't+', :values => ['2'] },
        't' => { :op => 't', :values => [''] },
        'w' => { :op => 'w', :values => [''] },
        '>t-2' => { :op => '>t-', :values => ['2'] },
        '<t-2' => { :op => '<t-', :values => ['2'] },
        't-2' => { :op => 't-', :values => ['2'] } },
      'number' => {
        'INV' => { :op => '=', :values => ['INV'] },
        '~IN' => { :op => '~', :values => ['IN'] },
        '!~IN' => { :op => '!~', :values => ['IN'] } },
      'created_at' => {
        '>=2011-10-12' => { :op => '>=', :values => ['2011-10-12'] },
        '<t-2' => { :op => '<t-', :values => ['2'] },
        '>t-2' => { :op => '>t-', :values => ['2'] },
        't-2' => { :op => 't-', :values => ['2'] } },
      'updated_at' => {
        '>=2011-10-12' => { :op => '>=', :values => ['2011-10-12'] },
        '<t-2' => { :op => '<t-', :values => ['2'] },
        '>t-2' => { :op => '>t-', :values => ['2'] },
        't-2' => { :op => 't-', :values => ['2'] } },
      'balance' => {
        '=13.4' => { :op => '=', :values => ['13.4'] },
        '>=45' => { :op => '>=', :values => ['45'] },
        '<=125' => { :op => '<=', :values => ['125'] },
        '><10.5|20.5' => { :op => '><', :values => ['10.5', '20.5'] },
        '!*' => { :op => '!*', :values => [''] },
        '*' => { :op => '*', :values => [''] } },
      'due_amount' => {
        '=13.4' => { :op => '=', :values => ['13.4'] },
        '>=45' => { :op => '>=', :values => ['45'] },
        '<=125' => { :op => '<=', :values => ['125'] },
        '><10.5|20.5' => { :op => '><', :values => ['10.5', '20.5'] },
        '!*' => { :op => '!*', :values => [''] },
        '*' => { :op => '*', :values => [''] } },
      'amount' => {
        '=13.4' => { :op => '=', :values => ['13.4'] },
        '>=45' => { :op => '>=', :values => ['45'] },
        '<=125' => { :op => '<=', :values => ['125'] },
        '><10.5|20.5' => { :op => '><', :values => ['10.5', '20.5'] },
        '!*' => { :op => '!*', :values => [''] },
        '*' => { :op => '*', :values => [''] } }
    }

    default_filter = { 'status_id' => { :operator => 'o', :values => [''] } }

    to_test.each do |field, expression_and_expected|
      expression_and_expected.each do |filter_expression, expected|
        compatible_request :get, :index, :set_filter => 1, field => filter_expression

        assert_response :success
        assert_not_nil invoices_in_list
      end
    end
  end

  def test_index_with_query_grouped
    ['contact', 'assigned_to', 'status', 'currency',
     'language', 'project', 'order_number', 'contact_country', 'contact_city'].each do |by|
      @request.session[:user_id] = 1
      compatible_request :get, :index, :set_filter => 1, :group_by => by, :sort => 'status:desc'
      assert_response :success
    end
  end

  test 'should get index with sorting' do
    @request.session[:user_id] = 1
    compatible_request :get, :index, :sort => 'amount'
    assert_response :success
  end

  test 'should get index with grouping' do
    @request.session[:user_id] = 1
    compatible_request :get, :index, :group_by => 'assigned_to'
    assert_response :success
    assert_select 'div#contact_list tr.group'
  end
  test 'should get index with recurrent grouping' do
    @request.session[:user_id] = 1
    compatible_request :get, :index, :group_by => 'recurring_profile'
    assert_response :success
    assert_select 'div#contact_list tr.group'
  end

  test 'should get show' do
    # RedmineInvoices.settings[:total_including_tax] = true
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    invoice = Invoice.find(1)
    invoice.template = InvoiceTemplate.find(1)
    invoice.save

    compatible_request :get, :show, :id => 1
    assert_response :success

    assert_select 'div.subject h3', "Domoway - $3,265.65"
    assert_select 'div.invoice-lines table.list tr.line-data td.description', "Consulting work"
  end

  def test_show_unassigned
    # RedmineInvoices.settings[:total_including_tax] = true
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    invoice = Invoice.find(1)
    invoice.update_attribute(:assigned_to_id, nil)
    invoice.update_attribute(:template_id, nil)
    compatible_request :get, :show, :id => 1
    assert_response :success
    assert_select 'h2', "Invoice ##{invoice.number}"
  end

  def test_put_update_with_empty_discount
    @request.session[:user_id] = 1
    compatible_request :put, :update, :id => 1, :invoice => { :discount => '' }
    assert_equal 0, Invoice.find(1).discount
  end

  def test_get_show_as_pdf
    @request.session[:user_id] = 1
    Setting.default_language = 'en'
    field = InvoiceCustomField.create!(:name => 'Test custom field', :is_filter => true, :is_for_all => true, :field_format => 'string')
    invoice = Invoice.find(1)
    invoice.custom_field_values = { field.id => 'This is custom значение' }
    invoice.save

    compatible_request :get, :show, :id => 1, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
  end

  def test_should_get_show_as_pdf_without_client
    @request.session[:user_id] = 1
    Setting.default_language = 'en'
    invoice = Invoice.where(:id => 1).first
    invoice.update_attributes(:contact_id => nil)
    compatible_request :get, :show, :id => 1, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
  end

  test 'should get new' do
    @request.session[:user_id] = 2
    compatible_request :get, :new, :project_id => 1
    assert_response :success
    assert_select 'input#invoice_number'
    assert_select 'textarea#invoice_lines_attributes_0_description'
  end
  test 'should get new from context menu for spent time' do
    Issue.where(:id => [1, 2, 3]).update_all(:estimated_hours => 2.9)
    @request.session[:user_id] = 2
    compatible_request :get, :new, :project_id => 1, :issues_ids => [1, 2, 3], :line_grouping => 3, :time => 'spent'
    assert_response :success
    assert_select 'input#invoice_number'
    assert_select 'textarea#invoice_lines_attributes_0_description'
    assert_select 'textarea#invoice_lines_attributes_0_description', /Can.+t print recipes \(154\.25 hours\)/
    assert_select 'textarea#invoice_lines_attributes_0_description', /Error 281 when updating a recipe \(1\.00 hour\)/
  end

  test 'should get new from context menu for estimated time' do
    Issue.where(:id => [1, 2, 3]).update_all(:estimated_hours => 2.9)
    @request.session[:user_id] = 2
    compatible_request :get, :new, :project_id => 1, :issues_ids => [1, 2, 3], :line_grouping => 6
    assert_response :success
    assert_select 'input#invoice_number'
    assert_select 'textarea#invoice_lines_attributes_0_description'
    assert_select 'textarea#invoice_lines_attributes_1_description'
    assert_select 'textarea#invoice_lines_attributes_2_description'
    assert_select 'textarea#invoice_lines_attributes_0_description', /Feature request #2: Add ingredients categories/
    assert_select 'textarea#invoice_lines_attributes_1_description', /Bug #1: Can.+t print recipes/
    assert_select 'textarea#invoice_lines_attributes_2_description', /Bug #3: Error 281 when updating a recipe/
  end

  test 'should not get new by deny user' do
    @request.session[:user_id] = 4
    compatible_request :get, :new, :project_id => 1
    assert_response :forbidden
  end

  test 'should post create' do
    @request.session[:user_id] = 1
    assert_difference 'Invoice.count' do
      compatible_request :post, :create, 'invoice' => { 'number' => '1/005',
                                                        'discount' => '10.1',
                                                        'lines_attributes' => { '0' => { 'tax' => '10.2',
                                                                                         'price' => '140.0',
                                                                                         'quantity' => '23.0',
                                                                                         'units' => 'products',
                                                                                         '_destroy' => '',
                                                                                         'description' => 'Line one' } },
                                                        'discount_type' => '0',
                                                        'contact_id' => '1',
                                                        'invoice_date' => '2011-12-01',
                                                        'due_date' => '2011-12-03',
                                                        'description' => 'Test description',
                                                        'currency' => 'GBR',
                                                        'status_id' => '1' },
                                         'project_id' => 'ecookbook'
    end
    assert_redirected_to :controller => 'invoices', :action => 'show', :id => Invoice.last.id

    invoice = Invoice.where(:number => '1/005').first
    assert_not_nil invoice
    assert_equal 10.1, invoice.discount
    assert_equal 'Line one', invoice.lines.first.description
    assert_equal 10.2, invoice.lines.first.tax
    assert_equal 23.0, invoice.lines.first.quantity
    assert_equal 'products', invoice.lines.first.units
  end

  test 'should not post create by deny user' do
    @request.session[:user_id] = 4
    compatible_request :post, :create, :project_id => 1, 'invoice' => { 'number'=>'1/005' }
    assert_response :forbidden
  end

  test 'should get edit' do
    @request.session[:user_id] = 1
    compatible_request :get, :edit, :id => 1
    assert_response :success
    assert_select 'h2', 'Edit invoice'
    assert_select 'textarea#invoice_lines_attributes_0_description', 'Consulting work'
  end

  test 'should put update' do
    @request.session[:user_id] = 1

    invoice = Invoice.find(1)
    new_number = '2/001'

    compatible_request :put, :update, :id => 1, :invoice => { :number => new_number }
    assert_redirected_to :action => 'show', :id => '1'
    invoice.reload
    assert_equal new_number, invoice.number
  end

  test 'should post destroy' do
    @request.session[:user_id] = 1
    compatible_request :delete, :destroy, :id => 1
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Invoice.where(:id => 1).first
  end

  test 'should bulk_destroy' do
    @request.session[:user_id] = 1
    assert_not_nil Invoice.where(:id => 1).first
    compatible_request :delete, :bulk_destroy, :ids => [1], :project_id => 'ecookbook'
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Invoice.where(:id => 1).first
  end

  test 'should bulk_update' do
    @request.session[:user_id] = 1
    compatible_request :put, :bulk_update, :ids => [1, 2], :invoice => { :status_id => 2 }
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert(Invoice.find([1, 2]).all? { |e| e.status_id == 2 })
  end

  test 'should get context menu' do
    @request.session[:user_id] = 1
    compatible_xhr_request :get, :context_menu, :back_url => '/projects/ecookbok/invoices', :project_id => 'ecookbook', :ids => ['1', '2']
    assert_response :success
  end
  def test_get_client_view
    with_invoice_settings 'invoices_public_links' => 1 do
      invoice = Invoice.order('id DESC').first

      compatible_request :get, :client_view, :id => invoice.id, :token => invoice.token
      assert_response :success
    end
  end

  def test_get_client_view_with_layout_shows_paypal_button_when_enabled
    with_invoice_settings 'invoices_public_links' => 1, 'invoices_paypal_enabled' => 1, 'per_invoice_templates' => 1 do
      @request.session[:user_id] = 1
      invoice = Invoice.order('id DESC').first

      compatible_request :get, :client_view, :id => invoice.id, :token => invoice.token
      assert_match 'https://www.paypal.com/cgi-bin/webscr', @response.body.to_s
      assert_response :success
    end
  end

  def test_get_client_view_with_layout_do_not_shows_paypal_button_when_paypal_disabled
    with_invoice_settings 'invoices_public_links' => 1, 'per_invoice_templates' => 1, 'invoices_custom_template' => 1 do
      @request.session[:user_id] = 1
      invoice = Invoice.order('id DESC').first

      compatible_request :get, :client_view, :id => invoice.id, :token => invoice.token
      assert !@response.body.to_s.include?('https://www.paypal.com/cgi-bin/webscr')
      assert_response :success
    end
  end

  test 'should get index as csv' do
    field = InvoiceCustomField.create!(:name => 'Test custom field', :is_filter => true, :field_format => 'string')
    invoice = Invoice.find(1)
    invoice.custom_field_values = { field.id => 'This is custom значение' }
    invoice.save

    @request.session[:user_id] = 1
    compatible_request :get, :index, :format => 'csv'
    assert_response :success
    assert_not_nil invoices_in_list
    assert_match 'text/csv', @response.content_type
    assert @response.body.starts_with?('#,')
  end

  test 'should have import CSV link for user authorized to' do
    @request.session[:user_id] = 1
    compatible_request :get, :index, :project_id => 1
    assert_response :success
    assert_select 'a#import_from_csv'
  end

  test 'should post create with custom fields' do
    field = InvoiceCustomField.create!(:name => 'Test', :is_filter => true, :field_format => 'string')
    @request.session[:user_id] = 1
    assert_difference 'Invoice.count' do
      compatible_request :post, :create, 'invoice' => { 'number' => '1/005',
                                                        'discount' => '10',
                                                        'lines_attributes' => { '0' => { 'tax' => '10',
                                                                                         'price' => '140.0',
                                                                                         'quantity' => '23.0',
                                                                                         'units' => 'products',
                                                                                         '_destroy' => '',
                                                                                         'description' => 'Line one' } },
                                                        'discount_type' => '0',
                                                        'contact_id' => '1',
                                                        'invoice_date' => '2011-12-01',
                                                        'due_date' => '2011-12-03',
                                                        'description' => 'Test description',
                                                        'currency' => 'GBR',
                                                        'status_id' => '1',
                                                        'custom_field_values' => { field.id.to_s => 'one' } },
                                         'project_id' => 'ecookbook'
    end
    assert_redirected_to :controller => 'invoices', :action => 'show', :id => Invoice.last.id

    invoice = Invoice.where(:number => '1/005').first
    assert_not_nil invoice
    assert_equal 'GBR', invoice.currency
    assert_equal 'one', invoice.custom_field_values.last.value
  end

  def test_should_show_recurring_options_for_recurring_invoice
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    compatible_request :get, :edit, :id => 4
    assert_response :success

    assert_select 'input#invoice_is_recurring'
    assert_select 'select#invoice_recurring_period'
    assert_select 'select#invoice_recurring_action'
    assert_select 'input#invoice_recurring_occurrences'
  end

  def test_should_show_recurring_field_for_recurring_invoice
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    compatible_request :get, :show, :id => 4
    assert_response :success

    assert_match 'Recurring invoice', @response.body.to_s
    assert_match 'Recurring total', @response.body.to_s
    assert_match 'Recurring amount due', @response.body.to_s
    assert_match 'Recurrings', @response.body.to_s
  end

  def test_should_show_recurring_link_for_recurring_instance
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    compatible_request :get, :edit, :id => 5
    assert_response :success

    assert_select 'a.recurring_profile', 'Weekly'
    assert_match 'Recurring number', @response.body.to_s
  end

  def test_should_create_recurring_invoice
    @request.session[:user_id] = 1
    assert_difference 'Invoice.count' do
      compatible_request :post, :create, 'invoice' => { 'number' => '1/099',
                                                        'lines_attributes' => { '0' => { 'tax' => '10.2',
                                                                                         'price' => '140.0',
                                                                                         'quantity' => '23.0',
                                                                                         'units' => 'products',
                                                                                         '_destroy' => '',
                                                                                         'description' => 'Line one' } },
                                                        'contact_id' => '1',
                                                        'invoice_date' => (Date.today - 5.days).to_s,
                                                        'due_date' => (Date.today + 5.days).to_s,
                                                        'description' => 'Test description',
                                                        'currency' => 'GBR',
                                                        'status_id' => '2',
                                                        'is_recurring' => 'true',
                                                        'recurring_period' => '3month',
                                                        'recurring_occurrences' => 2,
                                                        'recurring_action' => 1 },
                                         'project_id' => 'ecookbook'
    end
    assert_redirected_to :controller => 'invoices', :action => 'show', :id => Invoice.last.id

    invoice = Invoice.where(:number => '1/099').first
    assert_not_nil invoice
    assert_equal true, invoice.is_recurring?
    assert_equal '3month', invoice.recurring_period
    assert_equal 2, invoice.recurring_occurrences
    assert_equal 1, invoice.recurring_action
  end

  def test_should_post_create_with_lines_custom_field
    field = InvoiceLineCustomField.create!(:name => 'LineTest', :is_filter => true, :field_format => 'string')
    @request.session[:user_id] = 1
    assert_difference 'Invoice.count' do
      compatible_request :post, :create, 'invoice' => { 'number' => '1/099',
                                                        'lines_attributes' => { '0' => { 'tax' => '10',
                                                                                         'price' => '140.0',
                                                                                         'quantity' => '2.0',
                                                                                         'units' => 'products',
                                                                                         '_destroy' => '',
                                                                                         'description' => 'Test line',
                                                                                         'custom_field_values' => { "#{field.id}" => 'test value' } } },
                                                        'contact_id' => '1',
                                                        'invoice_date' => '2011-12-01',
                                                        'due_date' => '2011-12-03',
                                                        'description' => 'Test description',
                                                        'currency' => 'USD',
                                                        'status_id' => '1' },
                                         'project_id' => 'ecookbook'
    end
    assert_redirected_to :controller => 'invoices', :action => 'show', :id => Invoice.last.id

    invoice = Invoice.where(:number => '1/099').first
    assert_not_nil invoice
    assert_equal 'USD', invoice.currency
    assert_equal 'test value', invoice.lines.last.custom_field_values.last.value
  end

  def test_context_menu_multiple_invoices_of_same_project
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    compatible_request :get, :index, :params => { :f => ['status_id', 'ids'],
                                                  :invoices_list_style => 'list',
                                                  :object_type => 'invoice',
                                                  :op => { :ids => '=', :status_id => 'o' },
                                                  :set_filter => 1,
                                                  :v => { :ids => '1,2' } }
    assert_response :success

    #check if there are invoices with ids 1 and 2
    assert_select 'div#content div#contact_list table.contacts td.id a', '1'
    assert_select 'div#content div#contact_list table.contacts td.id a', '2'
  end

  def test_create_invoice_with_macros_in_number_and_subject
    @request.session[:user_id] = 1

    compatible_request :post, :create, 'invoice' => { 'number' => '1/099-{{month_short_name}}',
                                       'subject' => 'TEST_INVOICE_{{month_name}}',
                                       'lines_attributes' => { '0' => { 'tax' => '10',
                                                                        'price' => '140.0',
                                                                        'quantity' => '2.0',
                                                                        'units' => 'products',
                                                                        '_destroy' => '',
                                                                        'description' => 'Test line' } },
                                                                        'contact_id' => '1',
                                                                        'invoice_date' => '2011-12-01',
                                                                        'due_date' => '2011-12-03',
                                                                        'description' => 'Test description',
                                                                        'currency' => 'USD',
                                                                        'status_id' => '1' },
                                       'project_id' => 'ecookbook'

    invoice = Invoice.all.last
    assert invoice.number = "1/099-#{Date.today.strftime("%^B")}"
    assert invoice.subject = "TEST_INVOICE_#{Date.today.strftime("%^b")}"
  end

  def test_payment_amount_query_filter
    @request.session[:user_id] = 2
    Setting.default_language = 'en'

    @payment = InvoicePayment.new(:amount => 13.0, :description => 'Testing..', :payment_date => Date.today)
    @payment.invoice = Invoice.find(4)
    @payment.author = User.find(2)

    compatible_request :get, :index, :project_id => 2, :params => { :f => ['payment_amounts', 'status_id'],
                                                                    :op => { :payment_amounts => '>', :status_id => '*' },
                                                                    :v => { :payment_amounts => ['12'] },
                                                                    :set_filter => 1,
                                                                    :invoices_list_style => 'list',
                                                                    :object_type => 'invoice'
                                                                  }

    assert_response :success
    assert_select 'div#content div#contact_list table.contacts td.id a', '4'
  end

  def test_payment_description_query_filter
    @request.session[:user_id] = 2
    Setting.default_language = 'en'

    @payment = InvoicePayment.new(amount: 13.0, payment_date: '2018-01-01', description: 'Test description.')
    @payment.invoice = Invoice.find(4)
    @payment.author = User.find(2)
    @payment.save!

    compatible_request :get, :index, project_id: 2,
                                     f: ['payment_descriptions', 'status_id'],
                                     op: { payment_descriptions: '=', status_id: '*' },
                                     v: { payment_descriptions: ['Test description.'] },
                                     set_filter: 1,
                                     invoices_list_style: 'list',
                                     object_type: 'invoice'

    assert_response :success
    assert_select 'div#content div#contact_list table.contacts td.id a', '4'
  end

  def test_payment_dates_query_filter
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    @payment = InvoicePayment.new(amount: 13.0, payment_date: '2018-01-01', description: 'Test description.')
    @payment.invoice = Invoice.find(4)
    @payment.author = User.find(2)
    @payment.save!

    compatible_request :get, :index, project_id: 2,
                                     f: ['payment_dates', 'status_id'],
                                     op: { payment_dates: '=', status_id: '*' },
                                     v: { payment_dates: ['2018-01-01'] },
                                     set_filter: 1,
                                     invoices_list_style: 'list',
                                     object_type: 'invoice'

    assert_response :success
    assert_select 'div#content div#contact_list table.contacts td.id a', '4'
  end

  class InvoicesPermissionTest < ActionController::TestCase
    fixtures :projects, :users, :roles, :members, :member_roles

    def setup
      @project = Project.find(1)
      @user = User.find(2)
      @request.session[:user_id] = @user.id
      @project.enable_module! :contacts_invoices
      @controller = InvoicesController.new
    end

    def test_that_user_with_add_invoices_can_get_new
      @user.roles_for_project(@project).first.add_permission! :add_invoices
      compatible_request :get, :new, :project_id => @project.id
      assert_response :success
    end

    def test_that_edit_invoices_allows_to_get_new
      @user.roles_for_project(@project).first.add_permission! :edit_invoices
      compatible_request :get, :new, :project_id => @project.id
      assert_response :success
    end

    def test_that_edit_own_invoices_also_allows_to_get_new
      @user.roles_for_project(@project).first.add_permission! :edit_own_invoices
      compatible_request :get, :new, :project_id => @project.id
      assert_response :success
    end

    def test_that_user_with_add_invoices_can_post_on_create
      @user.roles_for_project(@project).first.add_permission! :add_invoices
      assert_difference 'Invoice.count' do
        compatible_request :post, :create, :project_id => @project.id,
                                           :invoice => {
                                             :number => '1/123',
                                             :status_id => 3,
                                             :invoice_date => '2018-02-16'
                                           }
      end
      assert_redirected_to invoice_url(Invoice.last)
    end

    def test_that_edit_invoices_allows_post_on_create
      @user.roles_for_project(@project).first.add_permission! :edit_invoices
      assert_difference 'Invoice.count' do
        compatible_request :post, :create, :project_id => @project.id,
                                           :invoice => {
                                             :number => '1/123',
                                             :status_id => 3,
                                             :invoice_date => '2018-02-16'
                                           }
      end
      assert_redirected_to invoice_url(Invoice.last)
    end

    def test_that_edit_own_invoices_also_allows_to_post_on_create
      @user.roles_for_project(@project).first.add_permission! :edit_own_invoices
      assert_difference 'Invoice.count' do
        compatible_request :post, :create, :project_id => @project.id,
                                           :invoice => {
                                             :number => '1/123',
                                             :status_id => 3,
                                             :invoice_date => '2018-02-16'
                                           }
      end
      assert_redirected_to invoice_url(Invoice.last)
    end
  end
end
