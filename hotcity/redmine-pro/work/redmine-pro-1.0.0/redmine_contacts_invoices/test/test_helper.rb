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

require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../redmine_contacts/test/test_helper')

def fixture_files_path
  "#{File.expand_path('..',__FILE__)}/fixtures/files/"
end

module RedmineInvoices
  module TestHelper
    def with_invoice_settings(options, &block)
      Setting.plugin_redmine_contacts_invoices.stubs(:[]).returns(nil)
      options.each { |k, v| Setting.plugin_redmine_contacts_invoices.stubs(:[]).with(k).returns(v) }
      yield
    ensure
      options.each { |k, v| Setting.plugin_redmine_contacts_invoices.unstub(:[]) }
    end
    def expenses_in_list
      ids = css_select('.expenses td.id').map { |tag| tag['text'].to_i }
      Expense.where(:id => ids).sort_by { |expense| ids.index(expense.id) }
    end

    def invoices_in_list
      ids = css_select('.invoices td.id').map { |tag| tag['text'].to_i }
      Invoice.where(:id => ids).sort_by { |invoice| ids.index(invoice.id) }
    end
  end

  class TestCase
    def uploaded_test_file(name, mime)
      ActionController::TestUploadedFile.new(ActiveSupport::TestCase.fixture_path + "/files/#{name}", mime, true)
    end

    def self.is_arrays_equal(a1, a2)
      (a1 - a2) - (a2 - a1) == []
    end

    def self.create_fixtures(fixtures_directory, table_names, class_names = {})
      if ActiveRecord::VERSION::MAJOR >= 4
        ActiveRecord::FixtureSet.create_fixtures(fixtures_directory, table_names, class_names = {})
      else
        ActiveRecord::Fixtures.create_fixtures(fixtures_directory, table_names, class_names = {})
      end
    end

    def self.prepare
      Role.find(1, 2, 3).each do |r|
        r.permissions << :view_contacts
        r.permissions << :view_invoices
        r.permissions << :view_expenses
        r.save
      end
      Role.find(1, 2).each do |r|
        r.permissions << :edit_contacts
        r.permissions << :edit_invoices
        r.permissions << :edit_expenses
        r.permissions << :delete_invoices
        r.permissions << :delete_expenses
        r.save
      end

      Project.find(1, 2, 3, 4, 5).each do |project|
        EnabledModule.create(:project => project, :name => 'contacts_module')
        EnabledModule.create(:project => project, :name => 'contacts_invoices')
        EnabledModule.create(:project => project, :name => 'contacts_expenses')
      end
    end
  end
end
