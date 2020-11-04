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

module ExpensesHelper

  def expense_status_tag(expense)
    status_tag = content_tag(:span, expense_status_name(expense.status_id))
    content_tag(:span, status_tag, :class => "tag-label-color expense-status #{expense_status_name(expense.status_id, true).to_s}")
  end

  def expense_status_name(status, code=false)
    return (code ? "draft" : l(:label_expense_status_draft)) unless collection_expense_statuses.map{|v| v[1]}.include?(status)

    status_data = collection_expense_statuses.select{|s| s[1] == status }.first[0]
    status_name = collection_expense_status_names.select{|s| s[1] == status}.first[0]
    return (code ? status_name : status_data)
  end

  def collection_expense_status_names
    [[:draft, Expense::DRAFT_EXPENSE],
     [:new, Expense::NEW_EXPENSE],
     [:billed, Expense::BILLED_EXPENSE],
     [:paid, Expense::PAID_EXPENSE]]
  end

  def expense_status_url(status_id, options={})
    {:controller => 'expenses',
     :action => 'index',
     :set_filter => 1,
     :project_id => @project,
     :fields => [:status_id],
     :values => {:status_id => [status_id]},
     :operators => {:status_id => '='}}.merge(options)
  end

  def collection_expense_statuses
    [[l(:label_expense_status_draft), Expense::DRAFT_EXPENSE],
     [l(:label_expense_status_new), Expense::NEW_EXPENSE],
     [l(:label_expense_status_billed), Expense::BILLED_EXPENSE],
     [l(:label_expense_status_paid), Expense::PAID_EXPENSE]]
  end

  def collection_for_expense_status_for_select(status_id)
    collection = collection_expense_statuses.map{|s| [s[0], s[1].to_s]}
    collection.insert 0, [l(:label_open_issues), "o"]
    collection.insert 0, [l(:label_all), ""]

    options_for_select(collection, status_id)

  end

  def expenses_is_no_filters
    (params[:status_id] == 'o' && (params[:period].blank? || params[:period] == 'all') && params[:contact_id].blank? && params[:is_billable].blank?)
  end

  def expenses_to_csv(expenses)
    decimal_separator = l(:general_csv_decimal_separator)
    encoding = 'utf-8'
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#",
                  'Expense date',
                  'Price',
                  'Currency',
                  'Description',
                  'Contact',
                  'Status',
                  'Created',
                  'Updated'
                  ]
      custom_fields = ExpenseCustomField.all
      custom_fields.each {|f| headers << f.name}
      # Description in the last column
      csv << headers.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }
      # csv lines
      expenses.each do |expense|
        fields = [expense.id,
                  format_date(expense.expense_date),
                  expense.price,
                  expense.currency,
                  expense.description,
                  !expense.contact.blank? ? expense.contact.name : '',
                  expense.status,
                  format_date(expense.created_at),
                  format_date(expense.updated_at)
                  ]
        expense.custom_field_values.each {|custom_value| fields << RedmineContacts::CSVUtils.csv_custom_value(custom_value) }
        csv << fields.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }
      end
    end
    export
  end

  def importer_link
    project_expense_imports_path
  end

  def importer_show_link(importer, project)
    project_expense_import_path(:id => importer, :project_id => project)
  end

  def importer_settings_link(importer, project)
    settings_project_expense_import_path(:id => importer, :project => project)
  end

  def importer_run_link(importer, project)
    run_project_expense_import_path(:id => importer, :project_id => project, :format => 'js')
  end

  def importer_link_to_object(expense)
    link_to expense.description, edit_expense_path(expense)
  end

  def _project_expenses_path(project, *args)
    if project
      project_expenses_path(project, *args)
    else
      expenses_path(*args)
    end
  end

end
