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

class PeopleReportsQuery < Query
  operators_by_filter_type[:time_interval] = %w[t ld w l2w m lm y]

  def initialize(attributes = nil, *args)
    super attributes

    self.filters ||= {}
    # Add report_date_period filter unless it's already there.
    filters.merge!('report_date_period' => { operator: 'm', values: [''] }) { |_, old_value| old_value }
  end

  def initialize_available_filters
    add_available_filter 'report_date_period', type: :time_interval, name: l(:label_people_filter_time_interval)

    author_values = collect_answered_users.collect { |user| [user.name, user.id.to_s] }
    add_available_filter 'staff', type: :list, name: l(:field_assigned_to), values: author_values
  end

  def build_from_params(params)
    if params[:fields] || params[:f]
      add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
    else
      available_filters.keys.each do |field|
        add_short_filter(field, params[field]) if params[field]
      end
    end
    self
  end

  def issues(options = {})
    scope = issue_scope.eager_load((options[:include] || []).uniq).
                        where(options[:conditions]).
                        limit(options[:limit]).
                        offset(options[:offset])
    scope
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def sql_for_staff_field(_field, operator, value)
    issue_table = Issue.table_name
    journal_table = Journal.table_name
    compare = operator == '=' ? 'IN' : 'NOT IN'
    staff_ids = value.join(',')
    "#{issue_table}.id IN(SELECT #{issue_table}.id FROM #{issue_table} INNER JOIN #{journal_table} ON #{journal_table}.journalized_id = #{issue_table}.id AND #{journal_table}.journalized_type = 'Issue' WHERE (#{journal_table}.user_id #{compare} (#{staff_ids})))"
  end

  private

  def collect_answered_users
    return [] unless project
    user_ids = Issue.joins(:project).joins(journals: :journal_message).visible.uniq.pluck(:assigned_to_id).compact
    User.where(:id => user_ids)
  end

  def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter = false)
    sql = ''
    first_day_of_week = l(:general_first_day_of_week).to_i
    date = Date.today
    day_of_week = date.cwday
    case operator
    when 'pre_t'
      sql = date_clause_selector(db_table, db_field, -1, -1, is_custom_filter)
    when 'pre_ld'
      sql = date_clause_selector(db_table, db_field, -2, -2, is_custom_filter)
    when 'pre_w'
      days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
      sql = date_clause_selector(db_table, db_field, - days_ago - 7, - days_ago - 1, is_custom_filter)
    when 'pre_l2w'
      days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
      sql = date_clause_selector(db_table, db_field, - days_ago - 28, - days_ago - 14 - 1, is_custom_filter)
    when 'pre_m'
      sql = date_clause_selector_for_date(db_table, db_field, (date - 1.month).beginning_of_month, (date - 1.month).end_of_month, is_custom_filter)
    when 'pre_lm'
      sql = date_clause_selector_for_date(db_table, db_field, (date - 2.months).beginning_of_month, (date - 2.months).end_of_month, is_custom_filter)
    when 'pre_y'
      sql = date_clause_selector_for_date(db_table, db_field, (date - 1.year).beginning_of_year, (date - 1.year).end_of_year, is_custom_filter)
    end
    sql = super(field, operator, value, db_table, db_field, is_custom_filter) if sql.blank?

    sql
  end

  def date_clause_selector(table, field, from, to, is_custom_filter)
    return date_clause(table, field, (from ? Date.today + from : nil), (to ? Date.today + to : nil)) if Redmine::VERSION.to_s < '3.0'
    date_clause(table, field, (from ? Date.today + from : nil), (to ? Date.today + to : nil), is_custom_filter)
  end

  def date_clause_selector_for_date(table, field, date_from, date_to, is_custom_filter)
    return date_clause(table, field, date_from, date_to) if Redmine::VERSION.to_s < '3.0'
    date_clause(table, field, date_from, date_to, is_custom_filter)
  end

  def issue_scope
    issues = Issue.visible.joins(:project, :journals => :journal_message).where(statement)
    Rails.version >= '5.1' ? issues.distinct : issues.uniq
  end
end
