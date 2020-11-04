# encoding: utf-8
#
# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

module AgileSprintsHelper
  def sprint_values_for_select_for(project = nil)
    grouped_sprints = AgileSprint.for_project(project).available.group_by(&:status)
    grouped_sprints.map do |status, sprints|
      [
        l("label_agile_sprint_list_#{AgileSprint.statuses.key(status)}"),
        sprints.map { |s| [s.to_s, s.id.to_s] }
      ]
    end
  end

  def sprint_status_values_for_select
    AgileSprint.statuses.map { |status, value| [l("label_agile_sprint_status_#{status}"), value] }
  end

  def duration_values_for_select
    [[l(:label_agile_sprint_duration_select), nil]] + (1..4).map { |week| [l("label_agile_sprint_duration_week_#{week}"), week] }
  end
end
