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

class ExpenseQuery < Query
  include RedmineCrm::MoneyHelper
  include ExpensesHelper
  include CrmQuery

  self.queried_class = Expense
  self.view_permission = :view_expenses if Redmine::VERSION.to_s >= '3.4' || RedmineContacts.unstable_branch?

  self.available_columns = [
    QueryColumn.new(:expense_date, :sortable => "#{Expense.table_name}.expense_date", :caption => :field_expense_date),
    QueryColumn.new(:price, :sortable => ["#{Expense.table_name}.currency", "#{Expense.table_name}.price"], :default_order => 'desc', :caption => :field_expense_price),
    QueryColumn.new(:status, :sortable => "#{Expense.table_name}.status_id", :groupable => true, :caption => :field_invoice_status),
    QueryColumn.new(:currency, :sortable => "#{Expense.table_name}.currency", :groupable => true, :caption => :field_invoice_currency),
    QueryColumn.new(:contact, :sortable => "#{Expense.table_name}.contact_id", :groupable => true, :caption => :field_invoice_contact),
    QueryColumn.new(:is_billable, :sortable => "#{Expense.table_name}.is_billable", :groupable => true, :caption => :label_invoice_is_billable),
    QueryColumn.new(:contact_city, :caption => :label_crm_contact_city, :groupable => "#{Address.table_name}.city", :sortable => "#{Address.table_name}.city"),
    QueryColumn.new(:contact_country, :caption => :label_crm_contact_country, :groupable => "#{Address.table_name}.country_code", :sortable => "#{Address.table_name}.country_code"),
    QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
    QueryColumn.new(:created_at, :sortable => "#{Expense.table_name}.created_at", :caption => :field_created_on),
    QueryColumn.new(:updated_at, :sortable => "#{Expense.table_name}.updated_at", :caption => :field_updated_on),
    QueryColumn.new(:assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => "#{Expense.table_name}.assigned_to_id"),
    QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement("authors")}),
    QueryColumn.new(:description, :sortable => "#{Expense.table_name}.description")
  ]

  def initialize(attributes = nil, *_args)
    super attributes
    self.filters ||= { 'status_id' => { :operator => 'o', :values => [''] } }
  end

  def initialize_available_filters
    add_available_filter 'ids', :type => :integer, :label => :label_expense_plural if Redmine::VERSION.to_s >= '3.3'
    add_available_filter 'expense_date', :type => :date, :label => :field_expense_date
    add_available_filter 'price', :type => :float, :label => :field_expense_price
    add_available_filter 'currency', :type => :list,
                                     :label => :field_invoice_currency,
                                     :values => collection_for_currencies_select(ContactsSetting.default_currency, ContactsSetting.major_currencies)
    add_available_filter 'is_billable', :type => :list, :label => :label_invoice_is_billable, :values => [[l(:general_text_yes), '1'], [l(:general_text_no), '0']]
    add_available_filter 'description', :type => :text
    add_available_filter 'updated_at', :type => :date_past, :label => :field_updated_on
    add_available_filter 'created_at', :type => :date, :label => :field_created_on

    add_available_filter('status_id',
      :type => :list_status, :values => collection_expense_statuses.map { |s| [s[0], s[1].to_s] }, :label => :field_invoice_status, :order => 1
    )

    add_available_filter 'contact_id', type: :contact, label: :field_invoice_contact

    initialize_project_filter
    initialize_author_filter
    initialize_assignee_filter
    initialize_contact_country_filter
    initialize_contact_city_filter
    add_custom_fields_filters(ExpenseCustomField.where(:is_filter => true))
    add_associations_custom_fields_filters :contact, :author, :assigned_to
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += CustomField.where(:type => 'ExpenseCustomField').all.map { |cf| QueryCustomFieldColumn.new(cf) }
    @available_columns += CustomField.where(:type => 'ContactCustomField').all.map { |cf| QueryAssociationCustomFieldColumn.new(:contact, cf) }
    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= [:expense_date, :description, :contact, :price, :status]
  end

  def sql_for_status_id_field(field, operator, value)
    sql = case operator
          when 'o'
            "#{queried_table_name}.status_id NOT IN (#{Expense::PAID_EXPENSE})"
          when 'c'
            "#{queried_table_name}.status_id IN (#{Expense::PAID_EXPENSE})"
          else
            sql_for_field(field, operator, value, queried_table_name, field)
          end
    sql || ''
  end

  def sql_for_is_billable_field(_field, operator, value)
    op = (operator == '=' ? 'IN' : 'NOT IN')
    va = value.map { |v| v == '0' ? ActiveRecord::Base.connection.quoted_false : ActiveRecord::Base.connection.quoted_true}.uniq.join(',')

    "#{Expense.table_name}.is_billable #{op} (#{va})"
  end

  def sql_for_due_price_field(field, operator, value)
    sql_for_field(field, operator, value, Expense.table_name, "price - #{Expense.table_name}.balance") +
      " AND #{Expense.table_name}.status_id IN (#{Expense::SENT_INVOICE}, #{Expense::PAID_INVOICE})" +
      " AND #{Expense.table_name}.due_date <= '#{ActiveRecord::Base.connection.quoted_date(Date.today)}' "
  end

  def expense_amount
    objects_scope.group("#{Expense.table_name}.currency").sum(:price)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def objects_scope(options={})
    scope = Expense.visible
    options[:search].split(' ').collect { |search_string| scope = scope.live_search(search_string) } if options[:search].present?
    scope = scope.includes((query_includes + (options[:include] || [])).uniq).
                  where(statement).
                  where(options[:conditions])
    scope
  end

  def query_includes
    includes = [:contact, :project]
    includes << { :contact => :address } if self.filters['contact_country'] || filters['contact_city'] ||
                                            [:contact_country, :contact_city].include?(group_by_column.try(:name))
    includes << :assigned_to if self.filters['assigned_to_id'] || (group_by_column && [:assigned_to].include?(group_by_column.name))
    includes
  end
end
