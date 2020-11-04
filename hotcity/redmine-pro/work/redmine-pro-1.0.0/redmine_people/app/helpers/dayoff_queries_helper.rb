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

module DayoffQueriesHelper
  def retrieve_query(klass = DayoffQuery)
    session_key = klass.name.underscore.to_sym
    if params[:set_filter] || session[session_key].nil?
      # Give it a name, required to be valid
      @query = klass.new(name: '_')
      @query.build_from_params(params)
      session[session_key] = {
        filters: @query.filters,
        group_by: @query.group_by,
        column_names: @query.column_names,
        sort: @query.sort_criteria.to_a,
        options: @query.options
      }
    else
      # retrieve from session
      @query = klass.new(
        name: '_',
        filters: session[session_key][:filters],
        group_by: session[session_key][:group_by],
        column_names: session[session_key][:column_names],
        sort_criteria: session[session_key][:sort],
        options: session[session_key][:options]
      )
      @query.project = @project
    end
    @query
  end
end
