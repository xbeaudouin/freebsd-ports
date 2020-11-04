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

class PeopleDataCollectorUserActivity

  def initialize(query)
    @query = query
    @days = detect_days_count
    @activities = collect_activities
  end

  def users
    @activities[:users].any? ? User.preload(:email_address).where(id: @activities[:users]).visible.order(:firstname, :lastname) : []
  end

  def entries
    @activities[:entries]
  end

  def days_count
    @days[:days_count]
  end

  def current_average
    @activities[:current][:average]
  end

  def average_progress
    @activities[:progress][:average]
  end

  def current_length
    @activities[:current][:length]
  end

  def length_progress
    @activities[:progress][:length]
  end

  private

  def detect_days_count
    raise ArgumentError, 'Time range must be defined' unless @query.filters['report_date_period']
    days_count = 0
    previous_days_count = 0
    today = Date.today
    case @query.filters['report_date_period'][:operator]
    when 't'
      days_count = previous_days_count = 1
    when 'ld'
      days_count = previous_days_count = 1
    when 'w'
      days_count = previous_days_count = 7
    when 'l2w'
      days_count = previous_days_count = 14
    when 'm'
      days_count = last_month_day(today)
      previous_days_count = last_month_day(today - 1.month)
    when 'lm'
      days_count = last_month_day(today - 1.month)
      previous_days_count = last_month_day(today - 2.month)
    when 'y'
      days_count = last_year_date(today)
      previous_days_count = last_year_date(today - 1.year)
    else
      raise ArgumentError, 'Unexpected value of the time range'
    end
    { days_count: days_count, previous_days_count: previous_days_count }
  end

  def last_month_day(date)
    date.end_of_month.day
  end

  def last_year_date(date)
    date.end_of_year.yday
  end

  def collect_activities
    activities = { users: [],
                   entries: {},
                   current:  { length: 0, average: 0 },
                   previous: { length: 0, average: 0 },
                   progress: { length: 0, average: 0 } }
    activity_hours = []
    total_duration = []

    if issues_required?
      @query.filtered_issues.each do |issue|
        update_activities_with(activities, date: issue.created_on.to_date, hour: local_hour(issue.created_on), user_id: issue.author_id)
        activity_hours << local_hour(issue.created_on)
      end
    end

    if journals_required?
      @query.filtered_journals.each do |journal|
        update_activities_with(activities, date: journal.created_on.to_date, hour: (local_hour journal.created_on), user_id: journal.user_id)
        activity_hours << (local_hour journal.created_on)
      end
    end

    if time_entries_required?
      @query.filtered_time_entries.each do |time_entry|
        update_activities_with(activities, date: time_entry.spent_on, hour: (local_hour time_entry.created_on), user_id: time_entry.user_id, duration: time_entry.hours)
        total_duration << time_entry.hours
      end
    end

    if activities[:users].any?
      previous_activity_hours = []
      previous_total_duration = []

      @query.filtered_previous_issues(activities[:users]).each { |issue| previous_activity_hours << local_hour(issue.created_on) } if issues_required?
      @query.filtered_previous_journals(activities[:users]).each { |journal| previous_activity_hours << local_hour(journal.created_on) } if journals_required?
      @query.filtered_previous_time_entries(activities[:users]).each { |time_entry| previous_total_duration << time_entry.hours } if time_entries_required?

      activities[:current][:length] = activity_hours.uniq.length
      activities[:current][:average] = total_duration.sum / @days[:days_count]

      activities[:previous][:length] = previous_activity_hours.uniq.length
      activities[:previous][:average] = previous_total_duration.sum / @days[:previous_days_count]

      activities[:progress][:average] = calculate_progress(activities[:current][:average], activities[:previous][:average])
      activities[:progress][:length] = calculate_progress(activities[:current][:length], activities[:previous][:length])
    end

    activities
  end

  def update_activities_with(activities, activity_data)
    return if anonymous_user_ids.include?(activity_data[:user_id])
    return if @query.activity_principal_ids.exclude?(activity_data[:user_id])

    user_id = activity_data[:user_id]
    hour = activity_data[:hour]
    duration = activity_data[:duration]

    activities[:users] << user_id unless activities[:users].include?(user_id)

    activities[:entries][user_id] ||= {}
    activities[:entries][user_id][:hours] ||= Hash.new(0)
    activities[:entries][user_id][:hours][hour] += 1 if hour

    activities[:entries][user_id][:spent_time] ||= 0
    activities[:entries][user_id][:spent_time] += duration if duration
    activities
  end

  def project
    @query.project
  end

  def filters
    @query.filters
  end

  def anonymous_user_ids
    @anonymous_user_ids ||= AnonymousUser.pluck(:id)
  end

  def issues_required?
    # when no activity type filter is defined
    # OR activity type is set to "create issue"
    # OR activity type is set to any other than non-"create issue" (that includes "create issue")
    return true unless filters['activity_type']

    return true if filters['activity_type'][:values].first == 'create_issue' && filters['activity_type'][:operator] == '='
    return true if filters['activity_type'][:values].first != 'create_issue' && filters['activity_type'][:operator] == '!'

    false
  end

  def journals_required?
    return true unless filters['activity_type']

    return true if filters['activity_type'][:values].first == 'update_issue' && filters['activity_type'][:operator] == '='
    return true if filters['activity_type'][:values].first != 'update_issue' && filters['activity_type'][:operator] == '!'

    false
  end

  def time_entries_required?
    return true unless filters['activity_type']

    return true if filters['activity_type'][:values].first == 'add_spent_time' && filters['activity_type'][:operator] == '='
    return true if filters['activity_type'][:values].first != 'add_spent_time' && filters['activity_type'][:operator] == '!'

    false
  end

  def calculate_progress(current_value, past_value)
    return 0 if past_value == current_value
    return 100 if past_value == 0
    return -100 if current_value == 0

    (current_value.to_f / past_value - 1) * 100
  end

  def local_hour(time)
    local_time = user_timezone ? time.in_time_zone(user_timezone) : (time.utc? ? time.localtime : time)
    local_time.hour
  end

  def user_timezone
    @user_timezone ||= User.current.time_zone
  end
end
