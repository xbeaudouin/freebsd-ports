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

class ProductLine < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to  :product
  belongs_to  :container, :polymorphic => true

  validates_presence_of :container
  validates_presence_of :description, :if => Proc.new { |line| line.product.blank? }
  validates_numericality_of :price, :quantity, :tax, :discount, :allow_nil => true
  validates_numericality_of :tax, :discount, :allow_nil => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100

  rcrm_acts_as_list :scope => :container
  acts_as_customizable
  acts_as_priceable :price, :total

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'product',
                  'product_id',
                  'description',
                  'quantity',
                  'price',
                  'tax',
                  'discount',
                  'position',
                  'custom_field_values'

  def total
    price.to_f * quantity.to_f * (1 - discount.to_f / 100)
  end

  def tax_to_s
    tax ? "#{"%.2f" % tax.to_f}%" : ''
  end

  def discount_to_s
    discount ? "#{"%.2f" % discount.to_f}%" : ''
  end

  def currency
    container.currency if container.respond_to?(:currency)
  end

  def tax_amount
    ContactsSetting.tax_exclusive? ? tax_exclusive : tax_inclusive
  end

  def tax_inclusive
    total - (total / (1 + tax.to_f / 100))
  end

  def tax_exclusive
    total * tax.to_f / 100
  end
end
