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

require_dependency 'custom_fields_helper'

module RedmineInvoices
  module Patches
    module CustomFieldsHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :custom_fields_tabs_without_invoices, :custom_fields_tabs
          alias_method :custom_fields_tabs, :custom_fields_tabs_with_invoices
        end
      end

      module InstanceMethods
        # Adds a rates tab to the user administration page
        def custom_fields_tabs_with_invoices
          tabs = custom_fields_tabs_without_invoices
          tabs << { :name => 'InvoiceCustomField', :partial => 'custom_fields/index', :label => :label_invoice_plural }
          tabs << { :name => 'InvoiceLineCustomField', :partial => 'custom_fields/index', :label => :label_invoices_invoice_line }
          tabs << { :name => 'ExpenseCustomField', :partial => 'custom_fields/index', :label => :label_expense_plural }
          tabs
        end
      end
    end
  end
end

if Redmine::VERSION.to_s > '2.5'
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << { :name => 'InvoiceCustomField', :partial => 'custom_fields/index', :label => :label_invoice_plural }
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << { :name => 'InvoiceLineCustomField', :partial => 'custom_fields/index', :label => :label_invoices_invoice_line }
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << { :name => 'ExpenseCustomField', :partial => 'custom_fields/index', :label => :label_expense_plural }
else
  unless CustomFieldsHelper.included_modules.include?(RedmineInvoices::Patches::CustomFieldsHelperPatch)
    CustomFieldsHelper.send(:include, RedmineInvoices::Patches::CustomFieldsHelperPatch)
  end
end
