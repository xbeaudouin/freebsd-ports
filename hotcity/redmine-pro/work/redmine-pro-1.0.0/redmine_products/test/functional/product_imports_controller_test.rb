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

class ProductImportsControllerTest < ActionController::TestCase
  include RedmineContacts::TestHelper

  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects])

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/', [:products,
                                                                                                                    :order_statuses,
                                                                                                                    :orders,
                                                                                                                    :product_lines])
  def fixture_files_path
    "#{File.expand_path('../..',__FILE__)}/fixtures/files/"
  end

  def setup
    RedmineProducts::TestCase.prepare
    User.current = nil
    @csv_file = Rack::Test::UploadedFile.new(fixture_files_path + 'new_product.csv', 'text/comma-separated-values')
  end

  test 'should open invoice import form' do
    @request.session[:user_id] = 1
    compatible_request :get, :new, :project_id => 1
    assert_response :success
    if Redmine::VERSION.to_s >= '3.2'
      assert_select 'form input#file'
    else
      assert_select 'form#import_form'
    end
  end

  test 'should create new import object' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      compatible_request :get, :create, :project_id => 1, :file => @csv_file
      assert_response :redirect
      assert_equal Import.last.class, ProductKernelImport
      assert_equal Import.last.user, User.find(1)
      assert_equal Import.last.project, 1
      assert_equal Import.last.settings.slice('project', 'separator', 'wrapper', 'encoding', 'date_format'), { 'project' => 1,
                                                                                                               'separator' => Rails.version >= '5.1' ? ';' : ',',
                                                                                                               'wrapper' => "\"",
                                                                                                               'encoding' => 'ISO-8859-1',
                                                                                                               'date_format' => '%m/%d/%Y' }
    end
  end

  test 'should open settings page' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      import = ProductKernelImport.new
      import.user = User.find(1)
      import.project = Project.find(1)
      import.file = @csv_file
      import.save!
      compatible_request :get, :settings, :id => import.filename, :project_id => 1
      assert_response :success
      assert_select 'form#import-form'
    end
  end

  test 'should show mapping page' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      import = ProductKernelImport.new
      import.user = User.find(1)
      import.settings = { 'project' => 1,
                          'separator' => ',',
                          'wrapper' => "\"",
                          'encoding' => 'UTF-8',
                          'date_format' => '%m/%d/%Y' }
      import.file = @csv_file
      import.save!
      compatible_request :get, :mapping, :id => import.filename, :project_id => 1
      assert_response :success
      assert_select "select[name='import_settings[mapping][name]']"
      assert_select "select[name='import_settings[mapping][status]']"
      assert_select 'table.sample-data tr'
      assert_select 'table.sample-data tr td', 'Test product'
      assert_select 'table.sample-data tr td', 'Child category 2'
    end
  end

  test 'should successfully import from CSV with new import' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      import = ProductKernelImport.new
      import.user = User.find(1)
      import.settings = { 'project' => 1,
                          'separator' => ',',
                          'wrapper' => "\"",
                          'encoding' => 'UTF-8',
                          'date_format' => '%m/%d/%Y' }
      import.file = @csv_file
      import.save!
      compatible_request :post, :mapping, :id => import.filename, :project_id => 1,
                                          :import_settings => { :mapping => { :name => 2, :status => 8, :description => 3 } }
      assert_response :redirect
      compatible_request :post, :run, :id => import.filename, :project_id => 1, :format => :js
      assert_equal Product.last.name, 'Test product'
      assert_equal Product.last.status, 'Inactive'
      assert_equal Product.last.description, 'Test_description'
    end
  end
end
