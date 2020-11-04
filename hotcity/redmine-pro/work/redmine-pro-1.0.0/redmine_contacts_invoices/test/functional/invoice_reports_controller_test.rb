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

class InvoiceReportsControllerTest < ActionController::TestCase
  include RedmineContacts::TestHelper
  include RedmineInvoices::TestHelper

  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers,
           :issue_categories, :enabled_modules, :enumerations, :attachments, :workflows

  RedmineInvoices::TestCase.create_fixtures(
    Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:invoices, :invoice_lines, :invoice_templates]
  )

  def setup
    Project.find(1).enable_module!(:contacts_invoices)
    @admin = User.find(1)
    @user = User.find(2)
  end

  # === Action :new ===

  def test_should_get_new_for_admin
    @request.session[:user_id] = @admin.id
    should_get_new invoice_id: 1
  end

  def test_should_get_new_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_invoices
    should_get_new invoice_id: 1
  end

  def test_should_not_get_new_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :new, invoice_id: 1
    assert_response :forbidden
  end

  def test_should_not_get_new_for_anonymous
    compatible_xhr_request :get, :new, invoice_id: 1
    assert_response :unauthorized
  end

  # === Action :create ===

  def test_should_create_invoice_reports_for_admin
    @request.session[:user_id] = @admin.id
    check_create_invoice_reports
  end

  def test_should_create_invoice_reports_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_invoices
    check_create_invoice_reports
  end

  def test_should_not_create_invoice_reports_without_permission
    @request.session[:user_id] = @user.id
    compatible_request :post, :create, invoice_id: 1, invoice_template: { ids: [1] }
    assert_response :forbidden
  end

  def test_should_not_create_invoice_reports_for_anonymous
    compatible_request :post, :create, invoice_id: 1, invoice_template: { ids: [1] }
    assert_response :redirect
  end

  def test_should_create_invoice_reports_by_token_for_anonymous
    with_invoice_settings 'invoices_public_links' => 1 do
      check_create_invoice_reports true
    end
  end

  def test_should_not_create_invoice_reports_by_token_without_public_links
    @request.session[:user_id] = @admin.id
    compatible_request :post, :create, Invoice.find(1).public_link_params([InvoiceTemplate.find(1)])
    assert_response :forbidden
  end

  def test_should_not_create_invoice_reports_with_invalid_token
    with_invoice_settings 'invoices_public_links' => 1 do
      compatible_request :post, :create, invoice_id: 1, invoice_template: { ids: [1] }, token: ''
      assert_response :forbidden
    end
  end

  # === Action :autocomplete ===

  def test_should_get_autocomplete_for_admin
    @request.session[:user_id] = @admin.id
    check_get_autocomplete
  end

  def test_should_get_autocomplete_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_invoices
    check_get_autocomplete
  end

  def test_should_not_get_autocomplete_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :autocomplete, q: ''
    assert_response :forbidden
  end

  def test_should_not_get_autocomplete_for_anonymous
    compatible_xhr_request :get, :autocomplete, q: ''
    assert_response :unauthorized
  end

  # === Action :preview ===

  def test_should_get_preview_for_admin
    @request.session[:user_id] = @admin.id
    check_get_preview
  end

  def test_should_get_preview_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_invoices
    check_get_preview
  end

  def test_should_not_get_preview_without_permission
    @request.session[:user_id] = @user.id
    compatible_request :get, :preview, invoice_id: 1, invoice_template: { ids: [1] }
    assert_response :forbidden
  end

  def test_should_not_get_preview_for_anonymous
    compatible_request :get, :preview, invoice_id: 1, invoice_template: { ids: [1] }
    assert_response :redirect
  end

  def test_should_get_preview_by_token_for_admin
    @request.session[:user_id] = @admin.id
    with_invoice_settings 'invoices_public_links' => 1 do
      check_get_preview_by_token
    end
  end

  def test_should_get_preview_by_token_for_regular_user
    @request.session[:user_id] = @user.id
    with_invoice_settings 'invoices_public_links' => 1 do
      check_get_preview_by_token
    end
  end

  def test_should_get_preview_by_token_for_anonymous
    with_invoice_settings 'invoices_public_links' => 1 do
      check_get_preview_by_token
    end
  end

  def test_should_not_get_preview_by_token_for_admin_without_public_links
    @request.session[:user_id] = @admin.id
    compatible_request :get, :preview, Invoice.find(1).public_link_params([InvoiceTemplate.find(1)])
    assert_response :forbidden
  end

  def test_should_not_get_preview_by_token_for_anonymous_without_public_links
    compatible_request :get, :preview, Invoice.find(1).public_link_params([InvoiceTemplate.find(1)])
    assert_response :forbidden
  end

  def test_should_not_get_preview_by_token_for_anonymous_with_invalid_token
    with_invoice_settings 'invoices_public_links' => 1 do
      compatible_request :get, :preview, invoice_id: 1, invoice_template: { ids: [1] }, token: ''
      assert_response :forbidden
    end
  end

  private

  # === Helpers for action :new ===

  def should_get_new(parameters)
    compatible_xhr_request :get, :new, parameters
    assert_response :success
    assert_match /ajax-modal/, response.body
  end

  # === Helpers for action :create ===

  def should_create_file(filename, file_type, parameters)
    compatible_request :post, :create, parameters
    assert_response :success
    assert_equal "application/#{file_type}", @response.content_type
    assert_equal %(attachment; filename="#{filename}"), @response.headers['Content-Disposition']
  end

  def should_create_invoice_report_by_template(token = false)
    invoice = Invoice.find(1)
    invoice_template = InvoiceTemplate.find(1)
    params = { invoice_id: invoice.id, invoice_template: { ids: [invoice_template.id] } }
    params[:token] = invoice.token_by([invoice_template.id]) if token
    should_create_file "#{invoice_template.name}.pdf", 'pdf', params
  end

  def should_create_invoice_reports_by_templates(token = false)
    invoice = Invoice.find(1)
    invoice_template_ids = [1, 2]
    params = { invoice_id: invoice.id, invoice_template: { ids: invoice_template_ids } }
    params[:token] = invoice.token_by(invoice_template_ids) if token
    should_create_file 'invoices reports.zip', 'zip', params
  end

  def check_create_invoice_reports(token = false)
    should_create_invoice_report_by_template(token)
    should_create_invoice_reports_by_templates(token)
  end

  # === Helpers for action :autocomplete ===

  def should_get_autocomplete(expected_invoice_template_ids, parameters)
    compatible_xhr_request :get, :autocomplete, parameters
    assert_response :success

    if expected_invoice_template_ids.empty?
      assert @response.body.blank?
    else
      assert_select 'input', count: expected_invoice_template_ids.size
      expected_invoice_template_ids.each do |id|
        assert_select %(input[name=?][value="#{id}"]), 'invoice_template[ids][]'
      end
    end
  end

  def check_get_autocomplete
    should_get_autocomplete [1, 2], q: ''
    should_get_autocomplete [1], q: 'first'
    should_get_autocomplete [2], q: 'second'
    should_get_autocomplete [1, 2], q: 'inv'
  end

  # === Helpers for action :preview ===

  def should_get_preview(parameters)
    compatible_request :get, :preview, parameters
    assert_response :success
  end

  def check_get_preview
    should_get_preview invoice_id: 1, invoice_template: { ids: [1] }
    should_get_preview invoice_id: 1, invoice_template: { ids: [1, 2] }
  end

  def check_get_preview_by_token
    invoice = Invoice.find(1)
    should_get_preview invoice_id: 1, invoice_template: { ids: [1] }, token: invoice.token_by([1])
    should_get_preview invoice_id: 1, invoice_template: { ids: [1, 2] }, token: invoice.token_by([1, 2])
  end
end
