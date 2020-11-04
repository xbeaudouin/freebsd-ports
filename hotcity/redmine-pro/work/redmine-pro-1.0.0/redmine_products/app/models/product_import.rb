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


class ProductImport
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include CSVImportable

  attr_accessor :file, :project, :quotes_type

  def klass
    Product
  end

  def build_from_fcsv_row(row)
    ret = Hash[row.to_hash.map { |k, v| [k.underscore.gsub(' ', '_'), force_utf8(v)] }].delete_if { |k, v| !klass.column_names.include?(k) }
    ret[:category_id] = ProductCategory.where(:name => row['category']).first.try(:id) if row['category']
    if row['status']
      active_locale = I18n.t(:label_products_status_active)
      ret[:status_id] = active_locale == row['status'] ? Product::ACTIVE_PRODUCT : Product::INACTIVE_PRODUCT
    end
    ret
  end
end
