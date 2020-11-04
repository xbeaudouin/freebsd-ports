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

class OrdersChartsController < ApplicationController
  before_action :find_optional_project, if: Proc.new { @project.blank? }
  accept_api_auth :show, :render_chart
  before_action :retrieve_charts_query

  menu_item :orders

  helper :queries
  helper :crm_queries
  include ProductsHelper
  include QueriesHelper
  require 'redmine_products'
  include RedmineProducts
  include CrmQueriesHelper

  def show
    @current_week_sum = orders_sum_by_period('current_week')
    @last_week_sum = orders_sum_by_period('last_week')
    @current_month_sum = orders_sum_by_period('current_month')
    @last_month_sum = orders_sum_by_period('last_month')
    @current_year_sum = orders_sum_by_period('current_year')
    @recent_orders = Order.by_project(@project).visible.limit(5).order('order_date DESC')
  end

  def render_chart
    render json: "RedmineProducts::Charts::#{params[:chart].camelize}".constantize.new(@query).chart_data
  end

  private

  def retrieve_charts_query
    if params[:query_id].present?
      @query = OrdersChartsQuery.find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
    elsif params[:set_filter] || session[:orders_charts_query].nil? || session[:orders_charts_query][:project_id] != (@project ? @project.id : nil)
      @query = OrdersChartsQuery.new(name: '_')
      @query.project = @project
      @query.build_from_params(params)
      session[:orders_charts_query] = {
        project_id: @query.project_id,
        filters: @query.filters,
        group_by: @query.group_by,
        column_names: @query.column_names,
        interval_size: @query.interval_size
      }
    else
      # retrieve from session
      @query = OrdersChartsQuery.new(name: '_',
        filters: session[:orders_charts_query][:filters] || session[:orders_query][:filters],
        group_by: session[:orders_charts_query][:group_by],
        column_names: session[:orders_charts_query][:column_names],
        interval_size: session[:orders_charts_query][:interval_size] || 'day'
      )
      @query.project = @project
    end
    @chart = @query.chart
  end

end
