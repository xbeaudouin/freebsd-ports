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
    class WeekViewBookingsChart
      attr_accessor :view, :months

      def initialize(project, query, _options = {})
        raise ArgumentError unless query

        @project = project
        @query = query
      end

      def empty?
        resource_bookings.empty? && time_entries.empty?
      end

      def project_schedules
        @project_schedules ||=
          if @project || @query.group_by_project?
            build_project_schedules
          else
            [global_project_schedule]
          end
      end

      private

      def date_from
        @date_from ||= @query.date_from
      end

      def date_to
        @date_to ||= date_from.next_day(6)
      end

      def resource_bookings
        @resource_bookings ||= @query.resource_bookings_between(date_from, date_to).to_a
      end

      def time_entries
        @time_entries ||= begin
          scope = TimeEntry.includes(:project, :issue, :activity, :user)
          if @project
            scope = scope.references(:project)
              .where("#{Project.table_name}.lft >= #{@project.lft} AND #{Project.table_name}.rgt <= #{@project.rgt}")
          end
          scope.where('spent_on BETWEEN ? AND ?', date_from, date_to).to_a
        end
      end

      def global_project_schedule
        @global_project_schedule ||=
          Helpers::ProjectSchedule.new(nil, date_from, date_to, resource_bookings, time_entries)
      end

      def resource_bookings_groups_by_project_id
        @resource_bookings_groups_by_project_id ||= resource_bookings.group_by(&:project_id)
      end

      def time_entries_groups_by_project_id
        @time_entries_groups_by_project_id ||= time_entries.group_by(&:project_id)
      end

      def projects
        @projects ||= (resource_bookings.map(&:project) + time_entries.map(&:project)).uniq(&:id)
      end

      def build_project_schedules
        projects.map do |project|
          Helpers::ProjectSchedule.new(
            project,
            date_from,
            date_to,
            resource_bookings_groups_by_project_id[project.id].to_a,
            time_entries_groups_by_project_id[project.id].to_a
          )
        end
      end
    end
  end
end
