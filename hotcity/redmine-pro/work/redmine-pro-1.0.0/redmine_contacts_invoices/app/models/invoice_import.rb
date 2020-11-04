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


class InvoiceImport
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include CSVImportable

  attr_accessor :file, :project, :quotes_type

  def klass
    Invoice
  end

  def build_from_fcsv_row(row)
    ret = Hash[row.to_hash.map { |k, v| [k.underscore.gsub(' ', '_'), force_utf8(v)] }].delete_if { |k, _v| !klass.column_names.include?(k) }
    ret[:status_id] = case row['status'].underscore
                      when 'estimate', '0'
                        0
                      when 'draft', '1'
                        1
                      when 'sent', '2'
                        2
                      when 'paid', '3'
                        3
                      when 'canceled', '4'
                        4
                      else
                        1
                      end
    ret[:number] = row['#']
    ret[:invoice_date] = Date.parse(row['invoice_date']) if row['invoice_date']
    ret[:discount] = row['discount'].to_f
    ret
  end
end
