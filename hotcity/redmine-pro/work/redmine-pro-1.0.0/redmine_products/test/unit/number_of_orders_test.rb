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

class NumberOfOrdersTest < ActiveSupport::TestCase
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

    datasets = RedmineProducts::Charts::NumberOfOrders.new(query).datasets
    assert_equal 1, datasets.length
    assert_equal [query.orders.count], datasets[0][:data]
  end

  def test_datasets_with_week_period_and_day_interval
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'w'
    query.filters['report_date_period'][:values] = ['']
    query.interval_size = 'day'

    expected = Array.new(Date.today.cwday, 0)
    expected[Date.today.wday] = query.orders.count
    datasets = RedmineProducts::Charts::NumberOfOrders.new(query).datasets

    assert_equal 1, datasets.length
    assert_equal expected, datasets[0][:data]
  end

  def test_datasets_with_month_period_and_day_interval
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'm'
    query.filters['report_date_period'][:values] = ['']
    query.interval_size = 'day'

    expected = Array.new(Date.today.day, 0)
    expected[Date.today.mday - 1] = query.orders.count
    datasets = RedmineProducts::Charts::NumberOfOrders.new(query).datasets

    assert_equal 1, datasets.length
    assert_equal expected, datasets[0][:data]
  end

  def test_datasets_with_year_period_and_quarter_interval
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'y'
    query.filters['report_date_period'][:values] = ['']
    query.interval_size = 'quarter'

    expected = Array.new(Date.today.month.fdiv(3).ceil, 0)
    expected[(Date.today.month - 1) / 3] = query.orders.count
    datasets = RedmineProducts::Charts::NumberOfOrders.new(query).datasets

    assert_equal 1, datasets.length
    assert_equal expected, datasets[0][:data]
  end

  def test_datasets_with_year_period_and_month_interval
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'y'
    query.filters['report_date_period'][:values] = ['']
    query.interval_size = 'month'

    expected = Array.new(Date.today.month, 0)
    expected[Date.today.month - 1] = query.orders.count
    datasets = RedmineProducts::Charts::NumberOfOrders.new(query).datasets

    assert_equal 1, datasets.length
    assert_equal expected, datasets[0][:data]
  end
end
