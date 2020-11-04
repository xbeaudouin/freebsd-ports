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
    module InvoiceLineDropPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
        end
      end
    end

    module InstanceMethods
      def item_product
        @invoice_line.product ? ProductDrop.new(@invoice_line.product) : nil
      end 

      def product_description
        @invoice_line.product ? @invoice_line.description : nil
      end

    end
  end
end

if ProductsSettings.invoices_plugin_installed? && ProductsSettings.invoices_fully_compatible?
  unless InvoiceLineDrop.included_modules.include?(RedmineProducts::Patches::InvoiceLineDropPatch)
    InvoiceLineDrop.send(:include, RedmineProducts::Patches::InvoiceLineDropPatch)
  end
end
