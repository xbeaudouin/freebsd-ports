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

class InvoiceLine < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  belongs_to :invoice

  validates_presence_of :description, :if => Proc.new { |line| line.product_id.blank? }
  validates_presence_of :price, :quantity
  validates_numericality_of :price, :quantity

  delegate :currency, :to => :invoice, :allow_nil => true

  after_save :save_invoice_amount
  after_destroy :save_invoice_amount_destroy

  rcrm_acts_as_list :scope => :invoice
  acts_as_priceable :price, :total, :tax_amount
  acts_as_customizable

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'description',
                  'price',
                  'quantity',
                  'tax',
                  'units',
                  'position',
                  'invoice_id',
                  'discount',
                  'custom_field_values',
                  'product_id'

  def total
    price.to_f * quantity.to_f * (1 - discount.to_f / 100)
  end

  def tax_amount
    (ContactsSetting.tax_exclusive? ? tax_exclusive : tax_inclusive)
  end

  def price=(prc)
    super prc.to_s.gsub(/,/, '.')
  end

  def quantity=(qnt)
    super qnt.to_s.gsub(/,/, '.')
  end

  def tax_to_s
    tax ? "#{"%.2f" % tax.to_f}%" : ''
  end

  def discount_to_s
    discount ? "#{"%.2f" % discount.to_f}%" : ''
  end

  def tax_inclusive
    total * (1 - (1 / (1 + tax.to_f / 100)))
  end

  def tax_exclusive
    total * tax.to_f / 100
  end

  def line_description
    description
  end

  private

  def save_invoice_amount
    invoice.calculate_amount
  end

  def save_invoice_amount_destroy
    invoice.lines.delete(self)
    invoice.calculate_amount
    invoice.save unless invoice.new_record?
  end
end
