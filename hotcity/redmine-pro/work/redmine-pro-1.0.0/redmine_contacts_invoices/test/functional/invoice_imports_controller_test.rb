# encoding: utf-8
#
# This file is a part of Redmine Invoices (redmine_contacts_invoices) plugin,
# invoicing plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# https://www.redmineup.com/
#
# redmine_contacts_invoices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts_invoices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts_invoices.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class InvoiceImportsControllerTest < ActionController::TestCase
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

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings])

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:invoices,
                                                                                                                             :invoice_lines])

  # TODO: Test for delete tags in update action

  def setup
    RedmineInvoices::TestCase.prepare

    User.current = nil
    @csv_file = Rack::Test::UploadedFile.new(fixture_files_path + 'invoices_correct.csv', 'text/comma-separated-values')
  end

  test 'should open invoice import form' do
    @request.session[:user_id] = 1
    compatible_request :get, :new, :project_id => 1
    assert_response :success
    if Redmine::VERSION.to_s >= '3.2'
      assert_select 'form input#file'
    else
      assert_select 'form.new_invoice_import'
    end
  end

  test 'should create new import object' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      compatible_request :get, :create, :project_id => 1, :file => @csv_file
      assert_response :redirect
      assert_equal Import.last.class, InvoiceKernelImport
      assert_equal Import.last.user, User.find(1)
      assert_equal Import.last.project, 1
      assert_equal Import.last.settings.slice('project', 'separator', 'wrapper', 'encoding', 'date_format'), { 'project' => 1,
                                                                                                               'separator' => ';',
                                                                                                               'wrapper' => "\"",
                                                                                                               'encoding' => 'ISO-8859-1',
                                                                                                               'date_format' => '%m/%d/%Y' }
    end
  end

  test 'should open settings page' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      import = InvoiceKernelImport.new
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
      import = InvoiceKernelImport.new
      import.user = User.find(1)
      import.settings = { 'project' => 1,
                          'separator' => ';',
                          'wrapper' => "\"",
                          'encoding' => 'UTF-8',
                          'date_format' => '%m/%d/%Y' }
      import.file = @csv_file
      import.save!
      compatible_request :get, :mapping, :id => import.filename, :project_id => 1
      assert_response :success
      assert_select "select[name='import_settings[mapping][number]']"
      assert_select "select[name='import_settings[mapping][status]']"
      assert_select 'table.sample-data tr'
      assert_select 'table.sample-data tr td', 'СЧЕТ-№11'
      assert_select 'table.sample-data tr td', 'Иван Грозный'
    end
  end

  test 'should successfully import from CSV with new import' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      import = InvoiceKernelImport.new
      import.user = User.find(1)
      import.settings = { 'project' => 1,
                          'separator' => ';',
                          'wrapper' => "\"",
                          'encoding' => 'UTF-8',
                          'date_format' => '%Y-%m-%d' }
      import.file = @csv_file
      import.save!
      compatible_request :post, :mapping, :id => import.filename,
                                          :project_id => 1,
                                          :import_settings => { :mapping => { :number => 0, :invoice_date => 1, :status => 7 } }
      assert_response :redirect
      compatible_request :post, :run, :id => import.filename, :project_id => 1, :format => :js
      assert_equal Invoice.last.number, 'СЧЕТ-№11'
      assert_equal Invoice.last.status, 'Draft'
    end
  end

end
