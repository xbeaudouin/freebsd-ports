# encoding: utf-8
#
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

module DayoffsHelper
  def dayoffs_list_partial(query = @query)
    query.graph_style? ? 'chart' : 'list'
  end

  def leave_planner_list_styles_for_select
    [[l(:label_people_graph), DayoffQuery::GRAPH_STYLE],
     [l(:label_people_list_list), DayoffQuery::TABLE_STYLE]]
  end

  def grouped_dayoff_query_results(items, query, &block)
    result_count_by_group = query.result_count_by_group
    previous_group, first = false, true
    items.each do |item|
      group_name = group_count = nil
      if query.grouped?
        group = query.group_by_column.value(item)
        if first || group != previous_group
          if group.blank? && group != false
            group_name = "(#{l(:label_blank_value)})"
          else
            group_name = format_object(group)
          end
          group_name ||= ""
          group_count = result_count_by_group ? result_count_by_group[group.try(:id)] : nil
        end
      end
      yield item, group_name, group_count
      previous_group, first = group, false
    end
  end
end
