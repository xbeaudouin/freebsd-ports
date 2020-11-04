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

class RecurringInvoicesServiceTest < ActiveSupport::TestCase
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
                                                                                                                    :contacts_projects])

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:invoices,
                                                                                                                             :invoice_lines])

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/', [:products,
                                                                                                                    :order_statuses,
                                                                                                                    :orders,
                                                                                                                    :product_lines]) if InvoicesSettings.products_plugin_installed?
  def setup
    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'
    User.current = nil
    @ri_service = RecurringInvoicesService.new
    @r_invoice = Invoice.find(4)
  end
  def test_method_invoice_max_recurring_number
    assert_equal 3, @ri_service.send(:invoice_max_recurring_number, Invoice.find(4))
  end

  def test_method_invoice_necessary_count
    old_date = @r_invoice.invoice_date
    old_occurrences = @r_invoice.recurring_occurrences

    assert_equal 2, @ri_service.send(:invoice_necessary_count, @r_invoice)

    @r_invoice.update_column(:invoice_date, 22.days.ago)
    assert_equal 0, @ri_service.send(:invoice_necessary_count, @r_invoice)
    @r_invoice.update_column(:invoice_date, old_date)

    @r_invoice.update_column(:recurring_occurrences, 3)
    assert_equal 0, @ri_service.send(:invoice_necessary_count, @r_invoice)

    @r_invoice.update_column(:recurring_occurrences, nil)
    assert_equal 2, @ri_service.send(:invoice_necessary_count, @r_invoice)
    @r_invoice.update_column(:recurring_occurrences, old_occurrences)
  end

  def test_method_needs_to_create_instances?
    old_date = @r_invoice.invoice_date
    assert_equal true, @ri_service.send(:needs_to_create_instances?, @r_invoice)

    @r_invoice.update_column(:invoice_date, 22.days.ago)
    assert_equal false, @ri_service.send(:needs_to_create_instances?, @r_invoice)
    @r_invoice.update_column(:invoice_date, old_date)
  end

  def test_necessary_instances_count
    old_recurring_period = @r_invoice.recurring_period
    old_date = @r_invoice.invoice_date
    assert_equal 5, @ri_service.send(:necessary_instances_count, @r_invoice)
    @r_invoice.recurring_period = '2week'
    assert_equal 2, @ri_service.send(:necessary_instances_count, @r_invoice)
    @r_invoice.recurring_period = '1month'
    assert_equal 1, @ri_service.send(:necessary_instances_count, @r_invoice)
    @r_invoice.recurring_period = '3month'
    assert_equal 0, @ri_service.send(:necessary_instances_count, @r_invoice)

    @r_invoice.update_column(:invoice_date, 400.days.ago)
    @r_invoice.recurring_period = '6month'
    assert_equal 2, @ri_service.send(:necessary_instances_count, @r_invoice)
    @r_invoice.recurring_period = '1year'
    assert_equal 1, @ri_service.send(:necessary_instances_count, @r_invoice)

    @r_invoice.update_column(:invoice_date, old_date)
    @r_invoice.update_column(:recurring_period, old_recurring_period)
  end

  def test_create_recurring_instances
    with_invoice_settings('invoices_recurring_email_from_address' => 'test@test.tst',
                          'invoices_recurring_email_subject' => 'Recurring test',
                          'invoices_recurring_email_template' => 'Hello {%contact.first_name%}. Recurring {%invoice.number%}',
                          'invoices_invoice_number_format' => 'Test %%ID%%') do
      assert_equal 2, @r_invoice.recurring_instances.count
      @ri_service.send(:create_recurring_instances, @r_invoice)
      assert_equal 4, @r_invoice.reload.recurring_instances.count
      invoice_last = Invoice.last
      assert_equal @r_invoice, invoice_last.recurring_profile
      assert_equal 5, invoice_last.recurring_number
      assert_equal @r_invoice.due_date + 5.weeks, invoice_last.due_date
      assert_equal @r_invoice.invoice_date + 5.weeks, invoice_last.invoice_date
      assert_equal 'Sent', invoice_last.status

      mail = ActionMailer::Base.deliveries.last
      assert_equal @r_invoice.contact.primary_email, mail.to.first
      assert_equal "invoice-#{invoice_last.number}.pdf", mail.attachments.first.filename
    end
  end

  def test_create_recurring_instance_with_number_and_subject_macros
    macro_invoice = Invoice.create!(:number => "TEST-NUM-{{month_short-name}}", :subject => "TEST_SUBJ-{{month_name}}", :invoice_date => Date.today,
      :project => Project.all.first, :status_id => 1)
    @ri_service.send(:create_recurring_instance, macro_invoice, 1.week)
    recurring_invoice = macro_invoice.recurring_instances.last

    assert recurring_invoice.number, "TEST-NUM-#{Date.today.strftime("%^b")}"
    assert recurring_invoice.subject, "TEST_SUBJ-#{Date.today.strftime("%^B")}"
  end

  def test_send_email_to_assigned_recurring_create
    assigned_user = User.find(2)
    @r_invoice.update_column(:recurring_action, 0)

    with_invoice_settings('invoices_recurring_email_from_address' => 'test@test.tst',
                          'invoices_recurring_email_subject' => 'Recurring test',
                          'invoices_recurring_email_template' => 'Hello {%contact.first_name%}. Recurring {%invoice.number%}',
                          'invoices_invoice_number_format' => 'Test %%ID%%',
                          'invoices_recurring_notify_assigned' => '1') do
      assert_equal 2, @r_invoice.recurring_instances.count
      assert_equal assigned_user, @r_invoice.assigned_to
      @ri_service.send(:create_recurring_instances, @r_invoice)
      assert_equal 4, @r_invoice.reload.recurring_instances.count
      invoice_last = Invoice.last
      assert_equal assigned_user, invoice_last.assigned_to
      assert_equal 'Draft', invoice_last.status

      mail = ActionMailer::Base.deliveries.last
      assert_equal assigned_user.mail, mail.to.first
      assert_equal "Recurring invoice #{invoice_last.number}", mail.subject
    end

    @r_invoice.update_column(:recurring_action, 1)
  end
end
