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

class InvoicesDrop < Liquid::Drop

  def initialize(invoices)
    @invoices = invoices
  end

  def before_method(id)
    invoice = @invoices.where(:id => id).first || Invoice.new
    InvoiceDrop.new invoice
  end

  def all
    @all ||= @invoices.map do |invoice|
      InvoiceDrop.new invoice
    end
  end

  def visible
    @visible ||= @invoices.visible.map do |invoice|
      InvoiceDrop.new invoice
    end
  end

  def each(&block)
    all.each(&block)
  end

end


class InvoiceDrop < Liquid::Drop

  delegate :id,
           :number,
           :order_number,
           :invoice_date,
           :subject,
           :due_date,
           :description,
           :subtotal,
           :remaining_balance,
           :balance,
           :tax_amount,
           :tax_groups,
           :amount,
           :is_open?,
           :is_estimate?,
           :is_canceled?,
           :is_paid?,
           :is_sent?,
           :has_taxes?,
           :status,
           :language,
           :currency,
           :discount_type,
           :to => :@invoice

  def initialize(invoice)
    @invoice = invoice
  end

  def contact
    ContactDrop.new(@invoice.contact) if @invoice.contact
  end

  def discount
    @invoice.discount_amount
  end

  def project
    @invoice.project.name
  end

  def lines
    @invoice.lines.map{|line| InvoiceLineDrop.new line}
  end

  def discount_rate
    100 - @invoice.discount_rate * 100
  end
  def custom_field_values
    @invoice.custom_field_values
  end

  private

  def helpers
    Rails.application.routes.url_helpers
  end

end

class InvoiceLineDrop < Liquid::Drop

  delegate :id,
           :position,
           :description,
           :price,
           :price_to_s,
           :tax,
           :tax_to_s,
           :quantity,
           :units,
           :total,
           :total_to_s,
           :to => :@invoice_line

  def initialize(invoice_line)
    @invoice_line = invoice_line
  end

  def description
    @invoice_line.line_description
  end
  def custom_field_values
    @invoice_line.custom_field_values
  end

end
