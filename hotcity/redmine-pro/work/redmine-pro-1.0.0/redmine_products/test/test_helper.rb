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

# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../redmine_contacts/test/test_helper')

module RedmineProducts
  module TestHelper
    def compatible_request(type, action, parameters = {})
      return send(type, action, params: parameters) if Rails.version >= '5.1'
      send(type, action, parameters)
    end

    def compatible_xhr_request(type, action, parameters = {})
      return send(type, action, params: parameters, xhr: true) if Rails.version >= '5.1'
      xhr(type, action, parameters)
    end
  end
end

include RedmineProducts::TestHelper

class RedmineProducts::TestCase
  include ActionDispatch::TestProcess

  module TestHelper
    def products_in_list
      ids = css_select('.products input').map { |tag| tag['value'].to_i }
      Product.where(:id => ids).sort_by { |product| ids.index(product.id) }
    end

    def orders_in_list
      ids = css_select('.orders input').map { |tag| tag['value'].to_i }
      Order.where(:id => ids).sort_by { |order| ids.index(order.id) }
    end
  end

  def self.create_fixtures(fixtures_directory, table_names, class_names = {})
    if ActiveRecord::VERSION::MAJOR >= 4
      ActiveRecord::FixtureSet.create_fixtures(fixtures_directory, table_names, class_names = {})
    else
      ActiveRecord::Fixtures.create_fixtures(fixtures_directory, table_names, class_names = {})
    end
  end

  def self.prepare
    Setting.plugin_redmine_contacts['thousands_delimiter'] = ','
    Setting.plugin_redmine_contacts['decimal_separator'] = '.'
    Project.where(id: [1, 5]).each do |project|
      EnabledModule.create(project: project, name: 'orders')
      EnabledModule.create(project: project, name: 'products')
      EnabledModule.create(project: project, name: 'contacts')
      EnabledModule.create(project: project, name: 'deals')
    end

    Role.where(id: [1, 2, 3, 4]).each do |r|
      r.permissions << :view_contacts
      r.save
    end

    Role.where(id: [1, 2]).each do |r|
      # user_2, user_3
      r.permissions << :add_products
      r.permissions << :view_products
      r.permissions << :view_orders
      r.save
    end

    Role.where(id: [1]).each do |r|
      # user_2
      r.permissions << :import_products
      r.save
    end
  end
end
