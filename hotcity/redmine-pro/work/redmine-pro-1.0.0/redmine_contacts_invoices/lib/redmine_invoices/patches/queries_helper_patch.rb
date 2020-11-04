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

require_dependency 'queries_helper'

module RedmineInvoices
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method :column_value_without_invoices, :column_value
          alias_method :column_value, :column_value_with_invoices
        end
      end

      module InstanceMethods
        def column_value_with_invoices(column, list_object, value)
          if column.name == :subject && list_object.is_a?(Invoice)
            list_object.subject
          elsif column.name == :number && list_object.is_a?(Invoice)
            link_to(list_object.number, invoice_path(list_object))
          elsif column.name == :invoice_date && list_object.is_a?(Invoice)
            format_date(list_object.invoice_date)
          elsif column.name == :due_date && list_object.is_a?(Invoice)
            format_date(list_object.due_date)
          elsif [:amount, :price].include?(column.name) && list_object.is_a?(Invoice)
            list_object.send("#{column.name}_to_s")
          elsif [:balance, :remaining_balance].include?(column.name) && list_object.is_a?(Invoice)
            list_object.send("#{column.name}_to_s") if (list_object.is_paid? || list_object.is_sent?)
          elsif value.is_a?(Invoice)
            group_invoice_tag(value).html_safe
          elsif [:amount, :price].include?(column.name) && list_object.is_a?(Expense)
            list_object.send("#{column.name}_to_s")
          elsif column.name == :expense_date && list_object.is_a?(Expense)
            link_to format_date(list_object.expense_date), edit_expense_path(list_object)
          elsif value.is_a?(Expense)
            expense_tag(value, :no_contact => true, :plain => true)
          else
            column_value_without_invoices(column, list_object, value)
          end
        end
      end
    end
  end
end

unless QueriesHelper.included_modules.include?(RedmineInvoices::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedmineInvoices::Patches::QueriesHelperPatch)
end
