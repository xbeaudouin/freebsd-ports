# encoding: utf-8
#
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

module InvoiceImportsHelper
  def importer_link
    project_invoice_imports_path
  end

  def importer_show_link(importer, project)
    project_invoice_import_path(:id => importer, :project_id => project)
  end

  def importer_settings_link(importer, project)
    settings_project_invoice_import_path(:id => importer, :project => project)
  end

  def importer_run_link(importer, project)
    run_project_invoice_import_path(:id => importer, :project_id => project, :format => 'js')
  end

  def importer_link_to_object(invoice)
    link_to invoice.number, invoice_path(invoice)
  end
end
