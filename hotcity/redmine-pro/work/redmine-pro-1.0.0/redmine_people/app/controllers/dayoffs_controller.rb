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

class DayoffsController < ApplicationController
  before_action :require_login
  before_action :require_view_leave_permission, only: :index
  before_action :require_edit_leave_permission, except: :index
  before_action :find_dayoff, only: [:edit, :update, :destroy]

  helper :queries
  include DayoffQueriesHelper
  helper :sort
  include SortHelper

  def index
    retrieve_query
    sort_init(@query.sort_criteria.empty? ? @query.default_sort_criteria : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      if @query.graph_style?
        @dayoffs = @query.dayoffs.between(@query.date_from, @query.date_to).to_a
        @chart = RedminePeople::Charts::LeavePlannerChart.new(@dayoffs, @query.date_from, @query.date_to, @query.group_by)
      else
        @dayoff_count = @query.dayoff_count
        @dayoff_pages = Paginator.new(@dayoff_count, per_page_option, params['page'])
        @dayoffs = @query.dayoffs(order: sort_clause, offset: @dayoff_pages.offset, limit: @dayoff_pages.per_page)
      end
      @tags = Person.available_tags
    end
  end

  def new
    @dayoff = Dayoff.new
  end

  def create
    @dayoff = Dayoff.new
    @dayoff.safe_attributes = params[:dayoff]

    if @dayoff.save
      flash[:notice] = l(:notice_successful_create)
      render js: "window.location = '#{dayoffs_path}'"
    else
      render :new
    end
  end

  def edit
  end

  def update
    @dayoff.safe_attributes = params[:dayoff]

    if @dayoff.save
      flash[:notice] = l(:notice_successful_update)
      render js: "window.location = '#{dayoffs_path}'"
    else
      render :edit
    end
  end

  def destroy
    @dayoff.destroy
    redirect_to dayoffs_path, notice: l(:notice_successful_delete)
  end

  private

  def find_dayoff
    @dayoff = Dayoff.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def require_view_leave_permission
    render_403 unless User.current.allowed_people_to?(:view_leave)
  end

  def require_edit_leave_permission
    render_403 unless User.current.allowed_people_to?(:edit_leave)
  end
end
