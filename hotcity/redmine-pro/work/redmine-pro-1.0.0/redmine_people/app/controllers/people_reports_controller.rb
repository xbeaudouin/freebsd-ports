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

class PeopleReportsController < ApplicationController
  unloadable

  helper :people_reports
  helper :queries
  include QueriesHelper

  before_action :find_optional_project
  before_action :authorize_global
  before_action :find_query

  def show
    return render_404 unless @query

    @collector = PeopleDataCollectorManager.new.collect_data(@query) if @query.valid?
  end

  private

  def find_query
    report_query_class =
      case params[:report]
      when 'user_activity'
        PeopleReportsUserActivityQuery
      end
    return unless report_query_class

    if params[:set_filter] || session["people_reports_#{params[:report]}"].blank?
      @query = report_query_class.new(name: params[:report], project: @project)
                                 .build_from_params(params)

      session["people_reports_#{params[:report]}"] = {
        project_id: @query.project_id,
        filters: @query.filters
      }
    else
      @query = report_query_class.new(
        name: params[:report],
        project: @project,
        filters: session["people_reports_#{params[:report]}"][:filters])
    end
  end
end
