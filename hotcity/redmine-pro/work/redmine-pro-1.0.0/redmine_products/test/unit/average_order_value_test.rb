# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class AverageOrderValueTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :members,
           :member_roles,
           :roles,
           :enabled_modules,
           :versions,
           :enumerations

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts, :contacts_projects])

  RedmineProducts::TestCase.create_fixtures(
    Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/',
    [:products, :order_statuses, :orders, :product_lines]
  )

  def setup
    User.current = User.find(1)
    RedmineProducts::TestCase.prepare
  end

  def test_datasets_with_today_period_and_day_interval
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 't'
    query.filters['report_date_period'][:values] = ['']
    query.interval_size = 'day'

    chart = RedmineProducts::Charts::AverageOrderValue.new(query)
    assert_equal chart.currencies.count, chart.datasets.length

    rub_orders = query.orders.where(currency: 'RUB')
    expected = [rub_orders.map(&:amount).inject(:+).to_f / rub_orders.count]
    rub_average = chart.datasets.find { |row| row[:label] == 'RUB' }
    assert_equal expected, rub_average[:data]
  end

  def test_datasets_with_week_period_and_day_interval
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'w'
    query.filters['report_date_period'][:values] = ['']
    query.interval_size = 'day'

    chart = RedmineProducts::Charts::AverageOrderValue.new(query)
    assert_equal chart.currencies.count, chart.datasets.length

    usd_orders = query.orders.where(currency: 'USD')
    expected = Array.new(Date.today.cwday, 0.0)
    expected[Date.today.wday] = usd_orders.map(&:amount).inject(:+).to_f / usd_orders.count
    usd_average = chart.datasets.find { |row| row[:label] == 'USD' }
    assert_equal expected, usd_average[:data]
  end

  def test_datasets_with_month_period_and_day_interval
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'm'
    query.filters['report_date_period'][:values] = ['']
    query.interval_size = 'day'

    chart = RedmineProducts::Charts::AverageOrderValue.new(query)
    assert_equal chart.currencies.count, chart.datasets.length

    rub_orders = query.orders.where(currency: 'RUB')
    expected = Array.new(Date.today.day, 0.0)
    expected[Date.today.mday - 1] = rub_orders.map(&:amount).inject(:+).to_f / rub_orders.count
    rub_average = chart.datasets.find { |row| row[:label] == 'RUB' }
    assert_equal expected, rub_average[:data]
  end

  def test_datasets_with_year_period_and_quarter_interval
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'y'
    query.filters['report_date_period'][:values] = ['']
    query.interval_size = 'quarter'

    chart = RedmineProducts::Charts::AverageOrderValue.new(query)
    assert_equal chart.currencies.count, chart.datasets.length

    usd_orders = query.orders.where(currency: 'USD')
    expected = Array.new(Date.today.month.fdiv(3).ceil, 0.0)
    expected[(Date.today.month - 1) / 3] = usd_orders.map(&:amount).inject(:+).to_f / usd_orders.count
    usd_average = chart.datasets.find { |row| row[:label] == 'USD' }
    assert_equal expected, usd_average[:data]
  end

  def test_datasets_with_year_period_and_month_interval
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'y'
    query.filters['report_date_period'][:values] = ['']
    query.interval_size = 'month'

    chart = RedmineProducts::Charts::AverageOrderValue.new(query)
    assert_equal chart.currencies.count, chart.datasets.length

    rub_orders = query.orders.where(currency: 'RUB')
    expected = Array.new(Date.today.month, 0.0)
    expected[Date.today.month - 1] = rub_orders.map(&:amount).inject(:+).to_f / rub_orders.count
    rub_average = chart.datasets.find { |row| row[:label] == 'RUB' }
    assert_equal expected, rub_average[:data]
  end
end
