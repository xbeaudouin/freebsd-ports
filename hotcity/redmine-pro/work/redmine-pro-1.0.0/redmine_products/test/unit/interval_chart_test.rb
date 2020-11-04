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

class IntervalChartTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :members,
           :member_roles,
           :roles,
           :enabled_modules,
           :versions,
           :enumerations

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts, :contacts_projects])

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/', [:products, :order_statuses, :orders, :product_lines])

  def setup
    User.current = User.find(1)
    RedmineProducts::TestCase.prepare
  end

  def test_date_from_with_equals_operator
    query = OrdersChartsQuery.new(name: '_')
    query.filters['report_date_period'][:operator] = '='
    query.filters['report_date_period'][:values] = ['2018-03-30']

    date_from = RedmineProducts::Charts::IntervalChart.new(query).date_from
    assert_match (date_from - 1).to_s(:db), query.statement
  end

  def test_date_from_with_today_operator
    query = OrdersChartsQuery.new(name: '_')
    query.filters['report_date_period'][:operator] = 't'
    query.filters['report_date_period'][:values] = ['']

    date_from = RedmineProducts::Charts::IntervalChart.new(query).date_from
    assert_match (date_from - 1).to_s(:db), query.statement
  end

  def test_date_from_with_last_two_weeks_operator
    query = OrdersChartsQuery.new(name: '_')
    query.filters['report_date_period'][:operator] = 'l2w'
    query.filters['report_date_period'][:values] = ['']

    date_from = RedmineProducts::Charts::IntervalChart.new(query).date_from
    assert_match (date_from - 1).to_s(:db), query.statement
  end

  def test_date_from_with_any_operator
    query = OrdersChartsQuery.new(name: '_')
    query.filters['report_date_period'][:operator] = '*'
    query.filters['report_date_period'][:values] = ['']

    date_from = RedmineProducts::Charts::IntervalChart.new(query).date_from
    assert_equal query.orders.first.order_date, date_from
  end

  def test_date_from_with_more_than_days_ago_operator
    query = OrdersChartsQuery.new(name: '_')
    query.filters['report_date_period'][:operator] = '<t-'
    query.filters['report_date_period'][:values] = ['1']

    date_from = RedmineProducts::Charts::IntervalChart.new(query).date_from

    assert_equal query.orders.first.try(:order_date), date_from
  end

  def test_date_to_with_this_month_operator
    query = OrdersChartsQuery.new(name: '_')
    query.filters['report_date_period'][:operator] = 'm'
    query.filters['report_date_period'][:values] = ['']

    date_to = RedmineProducts::Charts::IntervalChart.new(query).date_to
    assert_match date_to.to_s(:db), query.statement
  end

  def test_date_to_with_between_operator
    query = OrdersChartsQuery.new(name: '_')
    query.filters['report_date_period'][:operator] = '><'
    query.filters['report_date_period'][:values] = ['2017-02-01', '2019-01-02']

    date_to = RedmineProducts::Charts::IntervalChart.new(query).date_to
    assert_match date_to.to_s(:db), query.statement
  end

  def test_date_to_with_any_operator
    query = OrdersChartsQuery.new(name: '_')
    query.filters['report_date_period'][:operator] = '*'
    query.filters['report_date_period'][:values] = ['']

    date_to = RedmineProducts::Charts::IntervalChart.new(query).date_to
    assert_equal query.orders.last.order_date, date_to
  end

  def test_date_to_with_less_than_days_ago_operator
    query = OrdersChartsQuery.new(name: '_')
    query.filters['report_date_period'][:operator] = '>t-'
    query.filters['report_date_period'][:values] = ['100']

    date_to = RedmineProducts::Charts::IntervalChart.new(query).date_to
    assert_equal query.orders.last.order_date, date_to
  end
end
