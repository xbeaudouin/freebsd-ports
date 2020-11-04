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

class ContactControllerTest < ActionController::TestCase
  include RedmineContacts::TestHelper

  fixtures :users,
           :projects,
           :roles,
           :members,
           :member_roles

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects])

  def setup
    RedmineProducts::TestCase.prepare
    @controller = ContactsController.new
    User.current = nil
  end

  def test_tab_product
    @request.session[:user_id] = 2

    contact_id = 1
    contact = Contact.find(contact_id)

    products = contact.products.visible.order("#{Product.table_name}.name")
    product_count = contact.products.group("#{Product.table_name}.id").sum("#{ProductLine.table_name}.quantity")

    compatible_request :get, :show, :id => contact_id, :project_id => 1, :tab => 'products'
    assert_response :success
    products.each do |product|
      assert_match "#{product_tag(product)} x #{product_count[product.id]}", response.body
    end
  end
end
