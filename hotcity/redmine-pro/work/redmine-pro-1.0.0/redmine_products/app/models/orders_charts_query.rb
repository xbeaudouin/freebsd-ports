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

class OrdersChartsQuery < OrderQuery
  DAY_INTERVAL     = 'day'.freeze
  WEEK_INTERVAL    = 'week'.freeze
  MONTH_INTERVAL   = 'month'.freeze
  QUARTER_INTERVAL = 'quarter'.freeze
  YEAR_INTERVAL    = 'year'.freeze

  TIME_INTERVALS = [DAY_INTERVAL, WEEK_INTERVAL, MONTH_INTERVAL, QUARTER_INTERVAL, YEAR_INTERVAL].freeze

  NUMBER_OF_ORDERS    = 'number_of_orders'.freeze
  TOTAL_SALES         = 'total_sales'.freeze
  AVERAGE_ORDER_VALUE = 'average_order_value'.freeze
  POPULAR_PRODUCTS    = 'popular_products'.freeze
  POPULAR_CATEGORIES  = 'popular_categories'.freeze

  CHARTS = [NUMBER_OF_ORDERS, TOTAL_SALES, AVERAGE_ORDER_VALUE, POPULAR_PRODUCTS, POPULAR_CATEGORIES].freeze

  def initialize(attributes = nil)
    super
    self.filters = {'report_date_period' => { operator: 'm', values: [''] }}.merge(self.filters) if self.filters['report_date_period'].blank?
  end

  def initialize_available_filters
    super
    delete_available_filter 'order_date'
    add_available_filter 'report_date_period', type: :date_past, label: :label_products_order_date
  end

  def orders(options = {})
    scope = Order.visible.includes((query_includes + (options[:include] || [])).uniq)
    options[:search].split(' ').collect { |search_string| scope = scope.live_search(search_string) } if options[:search].present?
    scope.where(statement).where(options[:conditions]).order(:order_date)
  end

  def build_from_params(params)
    if params[:fields] || params[:f]
      self.filters = {}
      add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
    else
      available_filters.keys.each do |field|
        add_short_filter(field, params[field]) if params[field]
      end
    end
    self.group_by = params[:group_by] || (params[:query] && params[:query][:group_by])
    self.column_names = params[:c] || (params[:query] && params[:query][:column_names])
    self.chart = params[:chart] || (params[:query] && params[:query][:chart])
    self.interval_size = params[:interval_size] || (params[:query] && params[:query][:interval_size])
    self
  end

  def chart
    CHARTS.include?(options[:chart]) ? options[:chart] : NUMBER_OF_ORDERS
  end

  def chart=(value)
    options[:chart] = value
  end

  def interval_size
    TIME_INTERVALS.include?(options[:interval_size]) ? options[:interval_size] : DAY_INTERVAL
  end

  def interval_size=(value)
    options[:interval_size] = value
  end

  def sql_for_report_date_period_field(field, operator, values)
    date = User.current.today

    case operator
    when 'w'
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = date.cwday
      days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
      sql_for_field(field, '><t-', [days_ago], Order.table_name, 'order_date')
    when 'm'
      days_ago = date - date.beginning_of_month
      sql_for_field(field, '><t-', [days_ago], Order.table_name, 'order_date')
    when 'y'
      days_ago = date - date.beginning_of_year
      sql_for_field(field, '><t-', [days_ago], Order.table_name, 'order_date')
    else
      sql_for_field(field, operator, values, Order.table_name, 'order_date')
    end
  end
end
