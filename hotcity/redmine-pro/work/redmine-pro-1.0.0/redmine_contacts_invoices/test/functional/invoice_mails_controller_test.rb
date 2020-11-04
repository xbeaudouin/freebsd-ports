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

class InvoiceMailsControllerTest < ActionController::TestCase
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
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings])

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:invoices,
                                                                                                                             :invoice_lines])

  def setup
    Project.find(1).enable_module!(:contacts)
    Project.find(1).enable_module!(:contacts_invoices)
    Project.find(5).enable_module!(:contacts_invoices)
    User.current = nil
  end

  def test_get_new
    with_invoice_settings 'invoices_email_current_user' => 0 do
      @request.session[:user_id] = 1
      compatible_request :post, :new, :invoice_id => 1
      assert_response :success
      assert_select 'label', :text => l('field_invoice_sent_flag')
      assert_select 'div.invoice-card div.invoice-name h3.invoice_number', :text => '1/001'
      assert_select 'div.invoice-card div.invoice-name div a', :text => 'Domoway'
    end
  end

  def test_get_new_by_deny_user
    with_invoice_settings 'invoices_email_current_user' => 0 do
      @request.session[:user_id] = 4
      compatible_request :post, :new, :invoice_id => 1
      assert_response 403
    end
  end

  def test_post_preview
    with_invoice_settings 'invoices_email_current_user' => 0 do
      @request.session[:user_id] = 1
      compatible_xhr_request :post, :preview_mail, :invoice_id => 1,
                                                   :"message-content" => '{%contact.name%} test message'
      assert_response :success
      assert_match 'Domoway test message', @response.body
    end
  end

  def test_send_mail_by_deny_user
    with_invoice_settings 'invoices_email_current_user' => 0 do
      @request.session[:user_id] = 4
      compatible_request :post, :send_mail, :invoice_id => 1,
                                            :"message-content" => 'test message',
                                            :subject => 'test subject'
      assert_response 403
    end
  end

  def test_send_mail
    with_invoice_settings 'invoices_email_current_user' => 0 do
      @request.session[:user_id] = 1
      message_content = "Hello {%contact.name%}\ntest message\n{%invoice.public_link%}"
      subject = 'Invoice {%invoice.number%} for {%contact.name%}'
      compatible_request :post, :send_mail, :invoice_id => 1,
                                            :mark_as_sent => 'yes',
                                            :bcc => 'test@mail.bcc',
                                            :"message-content" => message_content,
                                            :subject => subject
      mail = ActionMailer::Base.deliveries.last
      assert_not_nil mail
      assert_match /Hello Domoway/, mail.text_part.body.to_s
      assert_equal 'Invoice 1/001 for Domoway', mail.subject
      assert_equal 'domoway@mail.ru', mail.to.first
      assert_equal 'redmine@example.net', mail.from.first
      assert_equal 'test@mail.bcc', mail.bcc.first
      assert_match "invoices/1/client_view?token=#{Invoice.find(1).token}", mail.text_part.body.to_s
      assert_equal true, Invoice.find(1).is_sent?
    end
  end
  include InvoicesHelper
  include ActionView::Helpers::OutputSafetyHelper

  def test_send_mail_with_paypal_link
    with_invoice_settings 'invoices_email_current_user' => 0 do
      @request.session[:user_id] = 1
      message_content = '{%pay_online%}'
      subject = 'Invoice {%invoice.number%} for {%contact.name%}'
      compatible_request :post, :send_mail, :invoice_id => 1,
                                            :bcc => 'test@mail.bcc',
                                            :"message-content" => message_content,
                                            :subject => subject
      mail = ActionMailer::Base.deliveries.last
      assert_not_nil mail
      invoice = Invoice.find(1)
      assert_match paypal_code(invoice), mail.html_part.body.to_s
      assert !mail.text_part.body.to_s.include?('https://www.paypal.com/cgi-bin/webscr')
    end
  end
end
