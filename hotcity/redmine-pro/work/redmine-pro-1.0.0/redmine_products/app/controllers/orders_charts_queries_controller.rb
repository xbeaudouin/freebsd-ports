# This file is a part of Redmine Products (redmine_products) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_products is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_products is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_products.  If not, see <http://www.gnu.org/licenses/>.

class OrdersChartsQueriesController < ApplicationController
  menu_item :orders

  before_action :find_query, except: [:index, :new, :create]
  before_action :find_optional_project, only: [:new, :create]

  helper :queries

  def new
    @query = OrdersChartsQuery.new
    @query.user = User.current
    @query.project = @project
    unless User.current.allowed_to?(:manage_public_orders_queries, @project) || User.current.admin?
      @query.visibility = OrdersChartsQuery::VISIBILITY_PRIVATE
    end
    @query.build_from_params(params)
    @chart = @query.chart
  end

  def create
    @query = OrdersChartsQuery.new
    @query.user = User.current
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.build_from_params(params)
    @query.name = params[:query] && params[:query][:name]
    if User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      @query.visibility = (params[:query] && params[:query][:visibility]) || OrdersChartsQuery::VISIBILITY_PRIVATE
      @query.role_ids = params[:query] && params[:query][:role_ids] if Redmine::VERSION.to_s > '2.4'
    else
      @query.visibility = OrdersChartsQuery::VISIBILITY_PRIVATE
    end

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_orders_chart(query_id: @query)
    else
      render action: 'new', layout: !request.xhr?
    end
  end

  def edit
  end

  def update
    @query.project = nil if params[:query_is_for_all]
    @query.build_from_params(params)
    @query.name = params[:query] && params[:query][:name]
    if User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      @query.visibility = (params[:query] && params[:query][:visibility]) || OrdersChartsQuery::VISIBILITY_PRIVATE
      @query.role_ids = params[:query] && params[:query][:role_ids] if Redmine::VERSION.to_s > '2.4'
    else
      @query.visibility = OrdersChartsQuery::VISIBILITY_PRIVATE
    end

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_orders_chart query_id: @query
    else
      render action: 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to_orders_chart set_filter: 1
  end

private
  def find_query
    @query = OrdersChartsQuery.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:save_orders_queries, @project, global: true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def redirect_to_orders_chart(options)
    options[:project_id] = @project if @project
    redirect_to orders_charts_path(options)
  end
end
