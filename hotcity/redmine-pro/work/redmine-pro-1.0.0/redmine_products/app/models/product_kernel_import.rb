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

class ProductKernelImport < Import
  def klass
    Product
  end

  def saved_objects
    object_ids = saved_items.pluck(:obj_id)
    Product.where(:id => object_ids).order(:id)
  end

  def project=(project)
    settings['project'] = project.id
  end

  def project
    settings['project']
  end

  private

  def build_object(row, _item = nil)
    product = Product.new
    product.project = Project.find(settings['project'])
    product.author = user

    attributes = {}
    if name = row_value(row, 'name')
      attributes['name'] = name
    end

    if status = row_value(row, 'status')
      attributes['status_id'] = Product::ACTIVE_PRODUCT   if status == I18n.t(:label_products_status_active)
      attributes['status_id'] = Product::INACTIVE_PRODUCT if status == I18n.t(:label_products_status_inactive)
    end

    if code = row_value(row, 'code')
      attributes['code'] = code
    end

    if description = row_value(row, 'description')
      attributes['description'] = description
    end

    if price = row_value(row, 'price')
      attributes['price'] = price.to_f
    end

    if category = row_value(row, 'category')
      attributes['category_id'] = ProductCategory.where(:name => category).first.try(:id)
    end

    if currency = row_value(row, 'currency')
      attributes['currency'] = currency
    end

    attributes['custom_field_values'] = product.custom_field_values.inject({}) do |h, v|
      value = case v.custom_field.field_format
              when 'date'
                row_date(row, "cf_#{v.custom_field.id}")
              else
                row_value(row, "cf_#{v.custom_field.id}")
              end
      h[v.custom_field.id.to_s] = v.custom_field.value_from_keyword(value, product) if value
      h
    end

    product.send :safe_attributes=, attributes, user
    product
  end
end
