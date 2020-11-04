# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

class DayoffQuery < Query
  GRAPH_STYLE = 'graph'.freeze
  TABLE_STYLE = 'table'.freeze
  LIST_STYLES = [GRAPH_STYLE, TABLE_STYLE].freeze

  self.queried_class = Dayoff

  self.available_columns = [
    QueryColumn.new(:id, sortable: "#{Dayoff.table_name}.id", default_order: 'desc', caption: '#', frozen: true),
    QueryColumn.new(:user, sortable: lambda { User.fields_for_order_statement }),
    QueryColumn.new(:leave_type, sortable: "#{LeaveType.table_name}.name", caption: :field_leave_type),
    QueryColumn.new(:start_date, sortable: "#{Dayoff.table_name}.start_date", caption: :label_people_holiday_start_date),
    QueryColumn.new(:end_date, sortable: "#{Dayoff.table_name}.end_date", caption: :label_people_holiday_end_date),
    QueryColumn.new(:duration),
    QueryColumn.new(:notes),
    QueryColumn.new(:manager, sortable: "#{Person.table_name}.firstname", groupable: "#{PeopleInformation.table_name}.manager_id", caption: :label_people_manager),
    QueryColumn.new(:department, sortable: "#{Department.table_name}.name", groupable: "#{PeopleInformation.table_name}.department_id", caption: :label_people_department)
  ]

  def initialize(attributes = nil, *args)
    super attributes
    self.filters ||= {}
  end

  def initialize_available_filters
    add_available_filter 'user_id', type: :list_optional, values: author_values
    add_available_filter 'leave_type_id', type: :list_optional, values: LeaveType.all.map { |type| [type.name, type.id] }
    add_available_filter 'start_date', type: :date
    add_available_filter 'end_date', type: :date

    add_available_filter 'firstname', type: :string
    add_available_filter 'lastname', type: :string
    add_available_filter 'middlename', type: :string, name: l(:label_people_middlename)

    add_available_filter('gender', type: :list_optional,
                         values: [[l(:label_people_male), 0], [l(:label_people_female), 1]],
                         name: l(:label_people_gender))

    add_available_filter 'mail', type: :string

    add_available_filter 'address', type: :string, name: l(:label_people_address)
    add_available_filter 'phone', type: :string, name: l(:label_people_phone)
    add_available_filter 'skype', type: :string, name: l(:label_people_skype)
    add_available_filter 'twitter', type: :string, name: l(:label_people_twitter)
    add_available_filter 'facebook', type: :string, name: l(:label_people_facebook)
    add_available_filter 'linkedin', type: :string, name: l(:label_people_linkedin)
    add_available_filter 'job_title', type: :string, name: l(:label_people_job_title)

    add_available_filter 'manager_id', type: :people, values: Person.managers.map { |p| [p.name, p.id.to_s] }, name: l(:label_people_manager)
    add_available_filter('department_id', type: :list_optional, name: l(:label_people_department), values: departments) if departments.any?

    add_available_filter 'tags', type: :list, values: Person.available_tags.collect { |t| [t.name, t.name] }, name: l(:label_people_tags_plural)
  end

  def default_columns_names
    @default_columns_names ||= [:id, :user, :leave_type, :start_date, :end_date, :duration]
  end

  def default_sort_criteria
    [['id', 'desc']]
  end

  def base_scope
    scope = Dayoff.eager_load(:information).includes(:user, :leave_type, :department, :manager)

    if Redmine::VERSION.to_s >= '3.0'
      scope = scope.joins("LEFT OUTER JOIN #{EmailAddress.table_name} ON #{EmailAddress.table_name}.user_id = #{Dayoff.table_name}.user_id")
    end

    scope.where(statement)
  end

  def dayoff_count
    base_scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def dayoffs(options = {})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    base_scope
      .order(order_option)
      .joins(joins_for_order_statement(order_option.join(',')))
      .limit(options[:limit])
      .offset(options[:offset])
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def list_style
    LIST_STYLES.include?(options[:list_style]) ? options[:list_style] : GRAPH_STYLE
  end

  def list_style=(value)
    options[:list_style] = value
  end

  def graph_style?
    list_style == DayoffQuery::GRAPH_STYLE
  end

  def month
    @month ||= ((1..12).include?(options[:month].to_i) ? options[:month].to_i : User.current.today.month)
  end

  def year
    @year ||= (options[:year].to_i > 0 ? options[:year].to_i : User.current.today.year)
  end

  def month=(value) options[:month] = value end
  def year=(value) options[:year] = value end

  def date_from
    @date_from ||= Date.new(year, month, 1).prev_day(7)
  end

  def date_to
    @date_to ||= Date.new(year, month, -1).next_day(7)
  end

  def build_from_params(params)
    super
    self.list_style = params[:list_style] || (params[:query] && params[:query][:list_style])
    self.year = params[:year] || (params[:query] && params[:query][:year])
    self.month = params[:month] || (params[:query] && params[:query][:month])
    self
  end

  def self.define_sql_methods_for(model, *fields)
    fields.each do |f|
      define_method("sql_for_#{f}_field") do |field, operator, value|
        sql_for_field(field, operator, value, model.table_name, f)
      end
    end
  end

  define_sql_methods_for(User, :firstname, :lastname)
  define_sql_methods_for(PeopleInformation, :middlename, :gender, :address,
                         :phone, :skype, :twitter, :facebook, :linkedin, :job_title, :manager_id)

  def sql_for_mail_field(field, operator, value)
    if Redmine::VERSION.to_s >= '3.0'
      sql_for_field(field, operator, value, EmailAddress.table_name, :address)
    else
      sql_for_field(field, operator, value, User.table_name, :mail)
    end
  end

  def sql_for_department_id_field(field, operator, value)
    department_ids = value
    department_ids += Department.where(id: value).map(&:descendants).flatten.collect { |c| c.id.to_s }.uniq
    sql_for_field(field, operator, department_ids, PeopleInformation.table_name, 'department_id')
  end

  def sql_for_tags_field(field, operator, value)
    compare = operator_for('tags').eql?('=') ? 'IN' : 'NOT IN'
    person_ids = Person.tagged_with(value).map { |person| person.id }.join(',')
    "(#{Person.table_name}.id #{compare} (#{person_ids}))"
  end

  private

  def departments
    @departments ||= build_departments
  end

  def build_departments
    departments = []
    Department.department_tree(Department.order(:lft)) do |department, level|
      name_prefix = (level > 0 ? '-' * 2 * level + ' ' : '') # &nbsp;
      departments << [(name_prefix + department.name).html_safe, department.id.to_s]
    end
    departments
  end
end
