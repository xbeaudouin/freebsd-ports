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

class PopularCategoriesTest < ActiveSupport::TestCase
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
    [:products, :order_statuses, :orders, :product_lines, :product_categories]
  )

  def setup
    User.current = User.find(1)
    RedmineProducts::TestCase.prepare
  end

  def test_datasets_with_today_period
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 't'
    query.filters['report_date_period'][:values] = ['']

    chart = RedmineProducts::Charts::PopularCategories.new(query)
    assert_equal 1, chart.datasets.length

    data = query.orders.joins(lines: [product: :category]).group('product_categories.name').reorder('sum_product_lines_quantity DESC').limit(10).sum('product_lines.quantity')
    expected = data.map { |_, val| val.to_f }
    assert_equal expected, chart.datasets[0][:data]
  end

  def test_datasets_with_week_period
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'w'
    query.filters['report_date_period'][:values] = ['']

    chart = RedmineProducts::Charts::PopularCategories.new(query)
    assert_equal 1, chart.datasets.length

    data = query.orders.joins(lines: [product: :category]).group('product_categories.name').reorder('sum_product_lines_quantity DESC').limit(10).sum('product_lines.quantity')
    expected = data.map { |_, val| val.to_f }
    assert_equal expected, chart.datasets[0][:data]
  end

  def test_datasets_with_month_period
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'm'
    query.filters['report_date_period'][:values] = ['']

    chart = RedmineProducts::Charts::PopularCategories.new(query)
    assert_equal 1, chart.datasets.length

    data = query.orders.joins(lines: [product: :category]).group('product_categories.name').reorder('sum_product_lines_quantity DESC').limit(10).sum('product_lines.quantity')
    expected = data.map { |_, val| val.to_f }
    assert_equal expected, chart.datasets[0][:data]
  end

  def test_datasets_with_year_period
    query = OrdersChartsQuery.new(name: '_', project: Project.find(5))
    query.filters['report_date_period'][:operator] = 'y'
    query.filters['report_date_period'][:values] = ['']

    chart = RedmineProducts::Charts::PopularCategories.new(query)
    assert_equal 1, chart.datasets.length

    data = query.orders.joins(lines: [product: :category]).group('product_categories.name').reorder('sum_product_lines_quantity DESC').limit(10).sum('product_lines.quantity')
    expected = data.map { |_, val| val.to_f }
    assert_equal expected, chart.datasets[0][:data]
  end
end
