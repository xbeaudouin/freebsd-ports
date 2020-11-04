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

module RedmineProducts
  module Patches
    module InvoiceLinePatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          include Redmine::SafeAttributes

          safe_attributes :product, :product_id
          belongs_to :product

          alias_method :line_description_without_products, :line_description
          alias_method :line_description, :line_description_with_products
        end
      end
    end

    module InstanceMethods
      def line_description_with_products
        product ? product.name : line_description_without_products
      end
    end
  end
end

if ProductsSettings.invoices_plugin_installed? && ProductsSettings.invoices_fully_compatible?
  unless InvoiceLine.included_modules.include?(RedmineProducts::Patches::InvoiceLinePatch)
    InvoiceLine.send(:include, RedmineProducts::Patches::InvoiceLinePatch)
  end
end
