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

class RecurringInvoicesService
  include Rails.application.routes.url_helpers
  include InvoicesHelper

  def self.default_url_options
    { :host => Setting.host_name, :protocol => Setting.protocol }
  end

  def initialize
    @recurring_invoices = Invoice.recurring
  end

  def process_invoices
    @recurring_invoices.eager_load(:recurring_instances).find_each do |invoice|
      create_recurring_instances(invoice) if needs_to_create_instances?(invoice)
    end
  end

  private

  def invoice_max_recurring_number(invoice)
    invoice.recurring_instances.pluck(:recurring_number).max || 0
  end

  def invoice_necessary_count(invoice)
    occurrences = necessary_instances_count(invoice) - invoice_max_recurring_number(invoice)
    return occurrences unless invoice.recurring_occurrences.to_i > 0
    max_occurrences = invoice.recurring_occurrences - invoice_max_recurring_number(invoice)
    occurrences > max_occurrences ? max_occurrences : occurrences
  end

  def needs_to_create_instances?(invoice)
    return false if all_instances_created?(invoice)
    necessary_instances_count(invoice) > invoice_max_recurring_number(invoice)
  end

  def all_instances_created?(invoice)
    occurrences = invoice.recurring_occurrences
    return false if occurrences.nil? || occurrences.zero?
    occurrences <= invoice_max_recurring_number(invoice)
  end

  def necessary_instances_count(invoice)
    interval_step, interval = invoice.recurring_period.scan(/\A(\d+)(week|month|year)\z/).first
    duration_in_days = (Date.today - invoice.invoice_date.to_date).to_i
    necessary_count = case interval
                      when 'week'
                        duration_in_days / 7
                      when 'month'
                        duration_in_days / 30
                      when 'year'
                        duration_in_days / 365
                      end
    necessary_count /= interval_step.to_i if interval_step.to_i > 1
    necessary_count
  end

  def create_recurring_instances(invoice)
    time_internal = Invoice.recurring_interval_in_seconds[invoice.recurring_period]
    max_number = invoice_max_recurring_number(invoice)
    invoice_necessary_count(invoice).times do |next_internal|
      create_recurring_instance(invoice, time_internal * (max_number + next_internal + 1))
    end
  end

  def create_recurring_instance(invoice, time_offset)
    recurring_invoice = Invoice.new
    recurring_invoice.copy_from(invoice)
    recurring_invoice.status_id = Invoice::DRAFT_INVOICE
    recurring_invoice.number = "#{invoice.number}-#{invoice_max_recurring_number(invoice).next}"
    recurring_invoice.invoice_date = invoice.invoice_date + time_offset
    recurring_invoice.due_date = invoice.due_date + time_offset if invoice.due_date.present?
    recurring_invoice.recurring_profile_id = invoice.id
    recurring_invoice.recurring_number = invoice_max_recurring_number(invoice).next
    clean_recurring_attributes(recurring_invoice)
    recurring_invoice.paid_date = nil
    recurring_invoice.calculate_balance
    recurring_invoice.save!
    InvoicesMailer.recurring_notification(User.current, recurring_invoice).deliver if InvoicesSettings[:invoices_recurring_notify_assigned, invoice.project]
    return if invoice.recurring_action == 0 # Draft
    send_new_invoice(recurring_invoice)
  end

  def clean_recurring_attributes(recurring_invoice)
    recurring_invoice.is_recurring = nil
    recurring_invoice.recurring_period = nil
    recurring_invoice.recurring_occurrences = nil
    recurring_invoice.recurring_action = nil
  end

  def send_new_invoice(instance)
    begin
      delivered = InvoicesMailer.invoice(User.current, instance, message_params(instance)).deliver
      instance.update_attributes(:status_id => Invoice::SENT_INVOICE) if delivered
    rescue Exception => e
      Rails.logger.error "Recurring instance delivery error: #{e.message}"
    end
  end

  def message_params(instance)
    params = {}
    params[:form] = InvoicesSettings[:invoices_recurring_email_from_address, instance.project]
    params[:subject] = invoice_mail_macro(instance, InvoicesSettings[:invoices_recurring_email_from_address, instance.project].to_s)
    params[:message] = invoice_mail_macro(instance, InvoicesSettings[:invoices_recurring_email_template, instance.project].to_s)
    params
  end
end
