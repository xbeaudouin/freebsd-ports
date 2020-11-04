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

class ExpenseImport
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include Redmine::I18n
  include CSVImportable

  attr_accessor :file, :project, :quotes_type

  def build_from_fcsv_row(row)
    ret = Hash[row.to_hash.map { |k, v| [k.underscore.gsub(' ', '_'), force_utf8(v)] }].delete_if { |k, _v| !klass.column_names.include?(k) }
    ret[:expense_date] = row['expense date'].to_date rescue Date.strptime(row['expense date'], '%m/%d/%Y') if row['expense date']
    ret[:status_id] = case row['status']
                      when l(:label_expense_status_draft)
                        Expense::DRAFT_EXPENSE
                      when l(:label_expense_status_new)
                        Expense::NEW_EXPENSE
                      when l(:label_expense_status_billed)
                        Expense::BILLED_EXPENSE
                      when l(:label_expense_status_paid)
                        Expense::PAID_EXPENSE
                      end
    ret
  end

  def klass
    Expense
  end
end
