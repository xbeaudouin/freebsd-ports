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
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method :project_settings_tabs_without_invoices, :project_settings_tabs
          alias_method :project_settings_tabs, :project_settings_tabs_with_invoices
        end
      end

      module InstanceMethods
        # include ContactsHelper

        def project_settings_tabs_with_invoices
          tabs = project_settings_tabs_without_invoices

          tabs.push({ :name => 'invoices',
                      :action => :manage_invoices,
                      :partial => 'projects/settings/invoices_settings',
                      :label => :label_invoice_plural }) if User.current.allowed_to?(:manage_invoices, @project)

          tabs.push({ :name => 'invoice_templates',
                      :action => :manage_invoices,
                      :partial => 'projects/settings/invoice_templates',
                      :label => :label_invoice_templates }) if User.current.allowed_to?(:manage_invoices, @project)

          tabs
        end
      end
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineInvoices::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineInvoices::Patches::ProjectsHelperPatch)
end
