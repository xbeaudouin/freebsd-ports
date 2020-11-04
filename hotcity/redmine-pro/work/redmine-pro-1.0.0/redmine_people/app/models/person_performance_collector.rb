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

class PersonPerformanceCollector
  include Redmine::I18n

  MONTH = 'month'.freeze
  YEAR = 'year'.freeze
  INTERVAL_TYPES = [MONTH, YEAR].freeze

  ACTIVITY_VALUES = { yellow: 1, green: 2, dark_green: 3 }

  attr_reader :from, :to

  def initialize(person, interval_type, start_date)
    @person = person
    @workday_length = @person.workday_length
    @today = User.current.today
    @interval_type = interval_type

    if @interval_type == YEAR
      @from = start_date.try(:to_date) || @today.beginning_of_year
      @to = (@from.year == @today.year) ? @today : @from.end_of_year

      @prev_from = @from.ago(1.year).to_date
      @prev_to = (@to == @from.end_of_year) ? @prev_from.end_of_year : @to.ago(1.year).to_date
    else
      @from = start_date.try(:to_date) || @today.beginning_of_month
      @to = (@from.month == @today.month && @from.year == @today.year) ? @today : @from.end_of_month

      @prev_from = @from.ago(1.month).to_date
      @prev_to = (@to == @from.end_of_month) ? @prev_from.end_of_month : @to.ago(1.month).to_date
    end

    @calendar = Redmine::Helpers::Calendar.new(@today)
    @calendar.set_custom_events(PeopleHoliday.between(@prev_from, @to).to_a)
  end

  def total_hours
    @total_hours ||= calculate_total_hours(@from, @to)
  end

  def previous_total_hours
    @previous_total_hours ||= calculate_total_hours(@prev_from, @prev_to)
  end

  def weekends_hours
    @weekends_hours ||= @person.time_entries.where(spent_on: @calendar.non_working_days_list(@from, @to)).sum(:hours)
  end

  def previous_weekends_hours
    @previous_weekends_hours ||= @person.time_entries.where(spent_on: @calendar.non_working_days_list(@prev_from, @prev_to)).sum(:hours)
  end

  def performance
    @performance ||= performance_calculator(@from, @to)
  end

  def previous_performance
    @previous_performance ||= performance_calculator(@prev_from, @prev_to)
  end

  def overtime
    @overtime ||= overtime_calculator(@from, @to)
  end

  def previous_overtime
    @previous_overtime ||= overtime_calculator(@prev_from, @prev_to)
  end

  def chart_data
    @chart_data ||= (@interval_type == YEAR) ? glance_year_chart_data : histogram_data
  end

  def histogram_data
    max_spent_time = spent_times_by_dates.values.max || 0
    height_ratio = (max_spent_time > 0) ? ->(time) { time / max_spent_time } : ->(_time) { 0 }

    data = (@from..@to).map do |day|
      time = spent_times_by_dates.fetch(day, 0)
      { spent_time: time.round(1), height_ratio: height_ratio.call(time) }
    end

    if @workday_length > 0
      data.each do |column_data|
        column_data[:performance] = (column_data[:spent_time] * 100 / @workday_length).round
      end
    end

    data
  end

  def glance_year_chart_data
    spent_times_by_dates.map do |date, hours|
      { date: date, value: activity_count(hours), tooltip: activity_tooltip(hours) }
    end
  end

  def incomplete_period
    @from..@to if @to < @from.end_of_month
  end

  private

  def spent_times_by_dates
    @spent_times_by_dates ||= begin
      @person.time_entries
        .select('spent_on, SUM(hours) as time_per_day')
        .where('spent_on BETWEEN ? AND ?', @from, @to)
        .group(:spent_on)
        .order(:spent_on)
        .inject({}) do |spent_times, time_entry|
          spent_times[time_entry.spent_on] = time_entry.time_per_day
          spent_times
        end
    end
  end

  def calculate_total_hours(from, to)
    @person.time_entries.where('spent_on BETWEEN ? AND ?', from, to).sum(:hours)
  end

  def performance_calculator(from_date, to_date)
    total_required_hours = @workday_length * @calendar.working_days_list(from_date, to_date).size
    calculate_total_hours(from_date, to_date) * 100 / total_required_hours if total_required_hours > 0
  end

  def overtime_calculator(from_date, to_date)
    @person.time_entries
           .select('SUM(hours) as time_per_day')
           .where(spent_on: @calendar.working_days_list(from_date, to_date))
           .group(:spent_on)
           .to_a.sum(0.0) do |time_entry|
             time_entry.time_per_day.to_f > @workday_length ? time_entry.time_per_day.to_f - @workday_length : 0
           end
  end

  def activity_count(hours)
    if @workday_length.blank?
      ACTIVITY_VALUES[:green]
    elsif hours < @workday_length * 0.9
      ACTIVITY_VALUES[:yellow]
    elsif hours > @workday_length * 1.1
      ACTIVITY_VALUES[:dark_green]
    else
      ACTIVITY_VALUES[:green]
    end
  end

  def activity_tooltip(hours)
    s = hours.round(2).to_s + l(:label_people_hour)
    s << " | #{(hours * 100 / @workday_length).round}%" if @workday_length > 0
    s
  end
end
