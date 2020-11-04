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

class ExpenseKernelImport < Import

  def klass
    Expense
  end

  def saved_objects
    object_ids = saved_items.pluck(:obj_id)
    Expense.where(:id => object_ids).order(:id)
  end

  def project=(project)
    settings['project'] = project.id
  end

  def project
    settings['project']
  end

  private

  def build_object(row, _item = nil)
    expense = Expense.new
    expense.project = Project.find(settings['project'])
    expense.author = user

    attributes = {}
    if expense_date = row_value(row, 'expense_date')
      attributes['expense_date'] = Date.strptime(expense_date, settings['date_format'])
    end

    if status = row_value(row, 'status')
      attributes['status_id'] = status =~ /\A\d+\Z/ ? status : Expense::STATUSES_STRINGS.key(status)
    end

    if contact = row_value(row, 'contact')
      attributes['contact_id'] = Contact.by_full_name(contact).first.try(:id)
    end

    if number = row_value(row, 'number')
      attributes['number'] = number
    end

    if invoice_date = row_value(row, 'invoice_date')
      attributes['invoice_date'] = Date.parse(invoice_date)
    end

    if price = row_value(row, 'price')
      attributes['price'] = price.to_f
    end

    if currency = row_value(row, 'currency')
      attributes['currency'] = currency
    end

    if description = row_value(row, 'description')
      attributes['description'] = description
    end

    attributes['custom_field_values'] = expense.custom_field_values.inject({}) do |h, v|
      value = case v.custom_field.field_format
              when 'date'
                row_date(row, "cf_#{v.custom_field.id}")
              else
                row_value(row, "cf_#{v.custom_field.id}")
              end
      h[v.custom_field.id.to_s] = v.custom_field.value_from_keyword(value, expense) if value
      h
    end

    expense.send :safe_attributes=, attributes, user
    expense
  end
end
