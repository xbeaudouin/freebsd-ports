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

module RedmineResources
  module Charts
    class MyResourceBookingsChart
      include Redmine::I18n

      delegate :plans, :capacity_hours, :allocated_hours, :spent_hours, to: :user_schedule

      def initialize(user)
        raise ArgumentError unless user

        @user = user
      end

      def render_summary
        @summary ||=
          "(#{l(:label_resources_capacity)}: #{l(:label_f_hour_short, value: '%0.2f' % capacity_hours)}, " +
            "#{l(:label_resources_allocated)}: #{l(:label_f_hour_short, value: '%0.2f' % allocated_hours)}, " +
            " #{l(:label_resources_spent)}: #{l(:label_f_hour_short, value: '%0.2f' % spent_hours)})"
      end

      def title_url_options
        { controller: 'resource_bookings',
          action: 'index',
          set_filter: 1,
          f: [:assigned_to_id],
          op: { assigned_to_id: '=' },
          v: { assigned_to_id: [@user.id] },
          months: 1,
          date_from: date_from }
      end

      def empty?
        resource_bookings.empty? && time_entries.empty?
      end

      private

      def date_from
        @date_from ||= RedmineResources.beginning_of_week(@user)
      end

      def date_to
        @date_to ||= date_from.next_day(6)
      end

      def resource_bookings
        @resource_bookings ||=
          ResourceBooking
            .includes(:project, :issue)
            .between(date_from, date_to)
            .where(assigned_to: @user)
            .to_a
      end

      def time_entries
        @time_entries ||=
          TimeEntry
            .includes(:project, :issue, :activity)
            .where('spent_on BETWEEN ? AND ?', date_from, date_to)
            .where(user: @user)
            .to_a
      end

      def user_schedule
        @user_schedule ||=
          Helpers::UserSchedule.new(@user, date_from, date_to, resource_bookings, time_entries)
      end
    end
  end
end
