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

module RedmineInvoices
  module Patches
    module FieldFormatFormatPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.instance_eval do
          unloadable
          class << self
            alias_method :as_select_without_invoices, :as_select
            alias_method :as_select, :as_select_with_invoices
          end
        end
      end

      module ClassMethods
        def as_select_with_invoices(class_name = nil)
          select_tags = as_select_without_invoices(class_name)
          select_tags = select_tags.select { |tag| %w(int float date bool string link).include?(tag[1]) } if class_name == 'InvoiceLine'
          select_tags
        end
      end
    end
  end
end

unless Redmine::FieldFormat.included_modules.include?(RedmineInvoices::Patches::FieldFormatFormatPatch)
  Redmine::FieldFormat.send(:include, RedmineInvoices::Patches::FieldFormatFormatPatch)
end
