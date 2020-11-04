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

if InvoicesSettings.finance_plugin_installed?
  module RedmineInvoices
    module Patches
      module OperationPatch
        def self.included(base)
          base.send(:include, InstanceMethods)

          base.class_eval do
            has_one :invoice_payment, autosave: false

            alias_method 'editable_by?_without_redmine_invoices', :editable_by?
            alias_method :editable_by?, 'editable_by?_with_redmine_invoices'

            alias_method 'destroyable_by?_without_redmine_invoices', :destroyable_by?
            alias_method :destroyable_by?, 'destroyable_by?_with_redmine_invoices'

            if method_defined?(:unlinkable?)
              alias_method 'unlinkable?_without_redmine_invoices', :unlinkable?
              alias_method :unlinkable?, 'unlinkable?_with_redmine_invoices'
            end
          end
        end

        module InstanceMethods
          define_method('editable_by?_with_redmine_invoices') do |user, project = nil|
            return false if invoice_payment
            send('editable_by?_without_redmine_invoices', user, project)
          end

          define_method('destroyable_by?_with_redmine_invoices') do |user, project = nil|
            return false if invoice_payment
            send('destroyable_by?_without_redmine_invoices', user, project)
          end

          define_method('unlinkable?_with_redmine_invoices') do |user = User.current|
            return false if invoice_payment
            send('unlinkable?_without_redmine_invoices', user)
          end
        end
      end
    end
  end

  unless Operation.included_modules.include?(RedmineInvoices::Patches::OperationPatch)
    Operation.send(:include, RedmineInvoices::Patches::OperationPatch)
  end
end
