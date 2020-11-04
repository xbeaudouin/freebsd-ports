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

class ProductImportTest < ActiveSupport::TestCase
  fixtures :projects, :users

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/', [:products,
                                                                                                                    :product_categories,
                                                                                                                    :product_lines])

  def fixture_files_path
    "#{File.expand_path('../..',__FILE__)}/fixtures/files/"
  end

  def test_open_correct_csv
    test_project = Project.first
    product_import = ProductImport.new(
      :file => Rack::Test::UploadedFile.new(fixture_files_path + 'new_product.csv', 'text/comma-separated-values'),
      :project => test_project,
      :quotes_type => '"'
    )
    assert_difference('Product.count', 1) do
      assert_equal 1, product_import.imported_instances.count
      assert product_import.save
    end
    product = Product.last
    assert_equal '44332211',         product.code
    assert_equal 'Test product',     product.name
    assert_equal 'Test_description', product.description
    assert_equal 320.0,              product.price
    assert_equal 'Child category 2', product.category.name
    assert_equal test_project.id,    product.project.id
    assert_equal 'Inactive',         product.status
    assert_equal 'EUR',              product.currency
  end
end
