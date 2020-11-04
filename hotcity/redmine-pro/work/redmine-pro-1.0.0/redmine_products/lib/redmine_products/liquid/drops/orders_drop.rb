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

class OrdersDrop < ::Liquid::Drop
  def self.default_drop
    self.new Order.all
  end

  def initialize(orders)
    @orders = orders
  end

  def before_method(id)
    order = @orders.where(:id => id).first || Order.new
    OrderDrop.new order
  end

  def all
    @all ||= @orders.map do |order|
      OrderDrop.new order
    end
  end

  def visible
    @visible ||= @orders.visible.map do |order|
      OrderDrop.new order
    end
  end

  def each(&block)
    all.each(&block)
  end
end

class OrderDrop < ::Liquid::Drop
  delegate :id, :number, :subject, :order_date, :completed_date, :currency, :updated_at, :description, :amount, :created_at, :to => :@order

  def initialize(order)
    @order = order
  end

  def author
    UserDrop.new @order.author if @order.author
  end

  def assigned_to
    UserDrop.new @order.assigned_to if @order.assigned_to
  end

  def project
    ProjectDrop.new @order.project if @order.project
  end

  def contact
    ContactDrop.new @order.contact if @order.contact
  end

  def status
    @order.status.name if @order.status
  end

  def products
    @products ||= @order.products.map { |p| ProductDrop.new p }
  end

  def attachments
    return @attachments if @attachments
    @attachments = {}
    @order.attachments.each { |f| @attachments[f.filename] = f }
    @attachments
  end

  def custom_fields
    return @custom_fields if @custom_fields
    @custom_fields = {}
    @order.custom_field_values.each { |cfv| @custom_fields[cfv.custom_field.name] = cfv.value }
    @custom_fields
  end
end
