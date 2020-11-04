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

class InvoiceQuery < Query
  include RedmineCrm::MoneyHelper
  include InvoicesHelper
  include CrmQuery

  self.queried_class = Invoice
  self.view_permission = :view_invoices if Redmine::VERSION.to_s >= '3.4' || RedmineContacts.unstable_branch?

  self.available_columns = [
    QueryColumn.new(:number, :sortable => "#{Invoice.table_name}.number", :caption => :field_invoice_number),
    QueryColumn.new(:subject, :sortable => "#{Invoice.table_name}.subject", :caption => :field_invoice_subject),
    QueryColumn.new(:invoice_date, :sortable => "#{Invoice.table_name}.invoice_date", :caption => :field_invoice_date),
    QueryColumn.new(:amount, :sortable => ["#{Invoice.table_name}.currency", "#{Invoice.table_name}.amount"], :default_order => 'desc', :caption => :field_invoice_amount),
    QueryColumn.new(:balance, :sortable => ["#{Invoice.table_name}.currency", "#{Invoice.table_name}.balance"], :default_order => 'desc', :caption => :label_invoice_amount_paid),
    QueryColumn.new(:remaining_balance, :sortable => ["#{Invoice.table_name}.currency", "#{Invoice.table_name}.amount - #{Invoice.table_name}.balance"], :default_order => 'desc', :caption => :label_invoice_amount_due),
    QueryColumn.new(:status, :sortable => "#{Invoice.table_name}.status_id", :groupable => true, :caption => :field_invoice_status),
    QueryColumn.new(:currency, :sortable => "#{Invoice.table_name}.currency", :groupable => true, :caption => :field_invoice_currency),
    QueryColumn.new(:contact, :sortable => lambda { Contact.fields_for_order_statement }, :groupable => true, :caption => :field_invoice_contact),
    QueryColumn.new(:language, :sortable => "#{Invoice.table_name}.language", :groupable => true, :caption => :field_invoice_language),
    QueryColumn.new(:order_number, :sortable => "#{Invoice.table_name}.order_number", :groupable => true, :caption => :field_invoice_order_number),
    QueryColumn.new(:contact_city, :caption => :label_crm_contact_city, :groupable => "#{Address.table_name}.city", :sortable => "#{Address.table_name}.city"),
    QueryColumn.new(:contact_country, :caption => :label_crm_contact_country, :groupable => "#{Address.table_name}.country_code", :sortable => "#{Address.table_name}.country_code"),
    QueryColumn.new(:due_date, :sortable => "#{Invoice.table_name}.due_date", :caption => :field_invoice_due_date),
    QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
    QueryColumn.new(:created_at, :sortable => "#{Invoice.table_name}.created_at", :caption => :field_created_on),
    QueryColumn.new(:updated_at, :sortable => "#{Invoice.table_name}.updated_at", :caption => :field_updated_on),
    QueryColumn.new(:assigned_to, :sortable => lambda { User.fields_for_order_statement }, :groupable => "#{Invoice.table_name}.assigned_to_id"),
    QueryColumn.new(:author, :sortable => lambda { User.fields_for_order_statement('authors') }),
    QueryColumn.new(:recurring_profile, :sortable => "#{Invoice.table_name}.recurring_profile_id", :groupable => true),
    QueryColumn.new(:description)
  ]

  def initialize(attributes = nil, *_args)
    super attributes
    self.filters ||= { 'status_id' => { :operator => 'o', :values => [''] } }
  end

  def initialize_available_filters
    add_available_filter 'number', :type => :string, :label => :field_invoice_number
    add_available_filter 'subject', :type => :string, :label => :field_invoice_subject
    add_available_filter 'invoice_date', :type => :date, :label => :field_invoice_date
    add_available_filter 'amount', :type => :float, :label => :field_invoice_amount
    add_available_filter 'balance', :type => :float, :label => :label_invoice_amount_paid
    add_available_filter 'due_amount', :type => :float, :label => :label_invoice_amount_due
    add_available_filter 'recurring', :type => :list, :values => [[l(:general_text_yes), '1'], [l(:general_text_no), '0']], :label => :label_invoice_is_recurring
    add_available_filter 'recurring_profile', :type => :text, :label => :label_invoice_recurring_profile
    add_available_filter 'order_number', :type => :string, :label => :field_invoice_order_number
    add_available_filter 'currency', :type => :list,
                                     :label => :field_invoice_currency,
                                     :values => collection_for_currencies_select(ContactsSetting.default_currency, ContactsSetting.major_currencies)
    add_available_filter 'description', :type => :text
    add_available_filter 'due_date', :type => :date, :label => :field_invoice_due_date
    add_available_filter 'updated_at', :type => :date_past, :label => :field_updated_on
    add_available_filter 'created_at', :type => :date, :label => :field_created_on
    add_available_filter 'ids', :type => :integer, :label => :label_invoice

    add_available_filter('status_id', :type => :list_status, :values => collection_invoice_statuses.map { |s| [s[0], s[1].to_s] },
                                      :label => :field_invoice_status, :order => 1)
    add_available_filter 'payment_amounts', :type => :float, :label => :label_invoice_payment_amount
    add_available_filter 'payment_descriptions', :type => :string, :label => :label_invoice_payment_description
    add_available_filter 'payment_dates', :type => :date_past, :label => :label_invoice_payment_date

    add_available_filter 'contact_id', type: :contact, label: :field_invoice_contact

    initialize_project_filter
    initialize_author_filter
    initialize_assignee_filter
    initialize_contact_country_filter
    initialize_contact_city_filter
    add_custom_fields_filters(InvoiceCustomField.where(:is_filter => true))
    add_associations_custom_fields_filters :contact, :author, :assigned_to
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += CustomField.where(:type => 'InvoiceCustomField').all.map { |cf| QueryCustomFieldColumn.new(cf) }
    @available_columns += CustomField.where(:type => 'ContactCustomField').all.map { |cf| QueryAssociationCustomFieldColumn.new(:contact, cf) }
    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= [:number, :invoice_date, :subject, :contact, :amount, :status]
  end

  def sql_for_status_id_field(field, operator, value)
    sql = case operator
          when 'o'
            "#{queried_table_name}.status_id NOT IN (#{Invoice::PAID_INVOICE}, #{Invoice::CANCELED_INVOICE})"
          when 'c'
            "#{queried_table_name}.status_id IN (#{Invoice::PAID_INVOICE}, #{Invoice::CANCELED_INVOICE})"
          when 'd'
            "#{Invoice.table_name}.due_date <= '#{ActiveRecord::VERSION::MAJOR >= 4 ? self.class.connection.quoted_date(Date.today) : connection.quoted_date(Date.today)}' AND #{Invoice.table_name}.status_id = #{Invoice::SENT_INVOICE}"
          else
            sql_for_field(field, operator, value, queried_table_name, field)
          end
    sql || ''
  end

  def sql_for_due_amount_field(field, operator, value)
    sql_for_field(field, operator, value, Invoice.table_name, "amount - #{Invoice.table_name}.balance") +
      " AND #{Invoice.table_name}.status_id IN (#{Invoice::SENT_INVOICE}, #{Invoice::PAID_INVOICE})" +
      " AND #{Invoice.table_name}.due_date <= '#{ActiveRecord::VERSION::MAJOR >= 4 ? self.class.connection.quoted_date(Date.today) : connection.quoted_date(Date.today)}' "
  end
  def sql_for_recurring_field(_field, operator, value)
    op = (operator == '=' ? 'IN' : 'NOT IN')
    va = value.map { |v| v == '0' ? self.class.connection.quoted_false : self.class.connection.quoted_true }.uniq.join(',')

    "#{Invoice.table_name}.is_recurring #{op} (#{va})"
  end

  def sql_for_recurring_profile_field(_field, operator, value)
    profiles_sql =
      case operator
      when '~', '!~'
        "LOWER(#{Invoice.table_name}.number) #{'NOT' if operator == '!~'} LIKE LOWER('%#{value.join}%')"
      when '!*'
        "#{Invoice.table_name}.number IS #{'NOT' if operator == '*'} NULL"
      end
    profiles_invoice_ids = Invoice.where(profiles_sql).pluck(:id)
    sql = profiles_invoice_ids.empty? ? 'IS NULL' : "IN (#{profiles_invoice_ids.join(',')})"
    "#{Invoice.table_name}.recurring_profile_id #{sql}"
  end

  def sql_for_payment_amounts_field(field, operator, value)
    invoice_ids = InvoicePayment.select(:invoice_id).where(sql_for_field(field, operator, value, 'invoice_payments', 'amount')).to_sql
    "#{Invoice.table_name}.id IN (#{invoice_ids})"
  end

  def sql_for_payment_descriptions_field(field, operator, value)
    invoice_ids = InvoicePayment.select(:invoice_id).where(sql_for_field(field, operator, value, 'invoice_payments', 'description')).to_sql
    "#{Invoice.table_name}.id IN (#{invoice_ids})"
  end

  def sql_for_payment_dates_field(field, operator, value)
    invoice_ids = InvoicePayment.select(:invoice_id).where(sql_for_field(field, operator, value, 'invoice_payments', 'payment_date')).to_sql
    "#{Invoice.table_name}.id IN (#{invoice_ids})"
  end

  def invoiced_amount
    objects_scope.group("#{Invoice.table_name}.currency").sum(:amount)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def paid_amount
    objects_scope.sent_or_paid.group(:currency).sum(:balance)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def due_amount
    objects_scope.sent_or_paid.group(:currency).sum("#{Invoice.table_name}.amount - #{Invoice.table_name}.balance")
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def objects_scope(options={})
    scope = Invoice.visible
    options[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } unless options[:search].blank?
    scope = scope.includes((query_includes + (options[:include] || [])).uniq).
      where(statement).
      where(options[:conditions])
    scope
  end

  def query_includes
    includes = [:contact, :project]
    includes << {:contact => :address} if self.filters["contact_country"] ||
        self.filters["contact_city"] ||
        [:contact_country, :contact_city].include?(group_by_column.try(:name))
    includes << :assigned_to if self.filters["assigned_to_id"] || (group_by_column && [:assigned_to].include?(group_by_column.name))
    includes
  end
end
