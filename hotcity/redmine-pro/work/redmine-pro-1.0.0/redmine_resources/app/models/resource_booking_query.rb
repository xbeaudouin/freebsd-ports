# This file is a part of Redmine Resources (redmine_resources) plugin,
# resource allocation and management for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_resources is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_resources is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_resources.  If not, see <http://www.gnu.org/licenses/>.

class ResourceBookingQuery < Query
  include Redmine::Utils::DateCalculation

  MONTH_VIEW_CHART = 'month_view_chart'.freeze
  WEEK_VIEW_CHART = 'week_view_chart'.freeze
  CHART_TYPES = [MONTH_VIEW_CHART, WEEK_VIEW_CHART].freeze

  USER_GROUP = 'user'.freeze
  PROJECT_GROUP = 'project'.freeze
  GROUP_BY_VALUES = [USER_GROUP, PROJECT_GROUP].freeze
    
  self.queried_class = ResourceBooking
  self.view_permission = :view_resources if Redmine::VERSION.to_s >= '3.4'

  def initialize(attributes = nil, *args)
    super attributes
    self.filters ||= {}
  end

  def initialize_available_filters
    add_available_filter 'assigned_to_id', type: :list_optional, values: assigned_to_values
    if project.nil?
      add_available_filter 'project_id', type: :list_optional, values: all_projects_values
    end
    add_available_filter 'issue_id', type: :integer
  end

  def assigned_to_values
    assigned_to_values = []
    assigned_to_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
    assigned_to_values += users.sort_by(&:status).collect { |s| [s.name, s.id.to_s] }
    assigned_to_values
  end

  def base_scope
    ResourceBooking.visible.joins(:assigned_to, :project).includes(:issue).where(statement)
  end

  def resource_bookings_between(from, to)
    base_scope.between(from, to)
  end

  def resource_bookings_by_users(from, to)
    scope = ResourceBooking.between(from, to)
    if has_filter?('assigned_to_id')
      scope = scope.where(sql_by_filter('assigned_to_id', ResourceBooking.table_name, 'assigned_to_id'))
    end
    scope
  end
  def resource_bookings_with_ghost_bookings(from, to)
    approved_bookings = resource_bookings_between(from, to.next_day(7))
    booked_issue_ids = approved_bookings.map(&:issue_id)
    unbooked_issues = available_issues(from, to).reject { |issue| booked_issue_ids.include?(issue.id) }

    approved_bookings.reject { |rb| rb.start_date > to } +       # Exist bookings
      unbooked_issues.map { |issue| build_ghost_booking(issue) } # Ghost bookings
  end

  def chart_bookings(from, to)
    if show_ghost_bookings && to >= User.current.today
      resource_bookings_with_ghost_bookings(from, to)
    else
      resource_bookings_between(from, to)
    end
  end

  def show_issues; options[:show_issues] end
  def show_issues=(arg); set_boolean_option(:show_issues, arg) end
  def show_versions; options[:show_versions] end
  def show_versions=(arg); set_boolean_option(:show_versions, arg) end

  def show_ghost_bookings; options[:show_ghost_bookings] end
  def show_ghost_bookings=(arg); set_boolean_option(:show_ghost_bookings, arg) end

  def show_project_names; options[:show_project_names] end
  def show_project_names=(arg); set_boolean_option(:show_project_names, arg) end

  def show_spent_time; options[:show_spent_time] end
  def show_spent_time=(arg); set_boolean_option(:show_spent_time, arg) end

  def line_title_type; options[:line_title_type] end

  def line_title_type=(arg)
    if line_title_types.include?(arg)
      options[:line_title_type] = arg
    else
      raise ArgumentError.new("value must be one of: #{line_title_types.join(', ')}")
    end
  end

  def chart_type; options[:chart_type] end

  def chart_type=(arg)
    if CHART_TYPES.include?(arg)
      options[:chart_type] = arg
    else
      raise ArgumentError.new("value must be one of: #{CHART_TYPES.join(', ')}")
    end
  end

  def month_view_chart?
    chart_type == MONTH_VIEW_CHART
  end

  def chart_class
    if chart_type == WEEK_VIEW_CHART
      RedmineResources::Charts::WeekViewBookingsChart
    else
      RedmineResources::Charts::MonthViewBookingsChart
    end
  end

  def group_by_project?
    group_by == PROJECT_GROUP
  end

  def group_by_user?
    group_by == USER_GROUP
  end

  def date_from; options[:date_from] end
  def date_from=(arg); options[:date_from] = arg.to_date end

  def build_from_params(params)
    super
    self.show_issues = params[:show_issues] || (params[:query] && params[:query][:show_issues]) || true
    self.show_versions = params[:show_versions] || (params[:query] && params[:query][:show_versions]) || true
    self.show_ghost_bookings = params[:show_ghost_bookings] || (params[:query] && params[:query][:show_ghost_bookings])
    self.show_project_names = params[:show_project_names] || (params[:query] && params[:query][:show_project_names]) || true
    self.show_spent_time = params[:show_spent_time] || (params[:query] && params[:query][:show_spent_time]) || true
    self.line_title_type = params[:line_title_type] || (params[:query] && params[:query][:line_title_type]) || default_line_title_type
    self.chart_type = params[:chart_type] || (params[:query] && params[:query][:chart_type]) || MONTH_VIEW_CHART
    self.date_from = params[:date_from].presence || (params[:query] && params[:query][:date_from].presence) || RedmineResources.beginning_of_week
    self
  end

  private

  def set_boolean_option(name, value)
    options[name] = value == '1' || value == true
  end

  def available_issues(from, to)
    scope =
      Issue.visible(User.current, project: project).open
        .joins(:assigned_to)
        .where(due_date: from..to.next_day(7))
        .where("#{Issue.table_name}.done_ratio < 100")

    %w(assigned_to_id project_id).each do |field|
      scope = scope.where(sql_by_filter(field, Issue.table_name, field)) if has_filter?(field)
    end

    scope = scope.where(sql_by_filter('issue_id', Issue.table_name, 'id')) if has_filter?('issue_id')
    scope
  end

  def sql_by_filter(field, db_table, db_field)
    values = values_for(field).clone

    # "me" value substitution
    if field == 'assigned_to_id' && values.delete('me')
      values.push(User.current.logged? ? User.current.id.to_s : '0')
    end

    sql_for_field(field, operator_for(field), values, db_table, db_field)
  end
  def build_ghost_booking(issue)
    start_date = [issue.start_date || User.current.today, User.current.today].max
    end_date = ghost_booking_end_date(issue)

    ResourceBooking.new(
      project: issue.project,
      assigned_to: issue.assigned_to,
      issue: issue,
      start_date: start_date,
      end_date: end_date,
      hours_per_day: ghost_booking_hours_per_day(issue, start_date, end_date)
    )
  end

  def ghost_booking_end_date(issue)
    return issue.due_date if issue.due_date >= User.current.today

    remaining_hours = issue_remaining_hours(issue)
    workday_length = RedmineResources.default_workday_length
    if (remaining_hours && workday_length > 0)
      number_of_days = remaining_hours.fdiv(workday_length).ceil
      next_working_days(User.current.today, number_of_days).last
    end
  end

  def next_working_days(from_date, number_of_days)
    working_days = []
    while working_days.length < number_of_days
      working_days << from_date if workday?(from_date)
      from_date = from_date.next_day
    end
    working_days
  end

  def workday?(date)
    non_working_week_days.exclude?(date.cwday)
  end

  def ghost_booking_hours_per_day(issue, start_date, end_date)
    if (remaining_hours = issue_remaining_hours(issue))
      remaining_hours.fdiv(working_days(start_date, end_date + 1.day)).round(2)
    end
  end

  def issue_remaining_hours(issue)
    if issue.estimated_hours && issue.done_ratio < 100
      issue.estimated_hours * (100 - issue.done_ratio) / 100
    end
  end

  def line_title_types
    RedmineResources::Charts::MonthViewBookingsChart::LINE_TITLE_TYPES
  end

  def default_line_title_type
    RedmineResources::Charts::MonthViewBookingsChart::ISSUE_SUBJECT
      end
end
