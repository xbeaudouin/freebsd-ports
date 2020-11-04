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

class ExpenseImportTest < ActiveSupport::TestCase
  def fixture_files_path
    "#{File.expand_path('../..',__FILE__)}/fixtures/files/"
  end

  def test_open_correct_csv
    expense_import = ExpenseImport.new(
      :file => Rack::Test::UploadedFile.new(fixture_files_path + "expenses_correct.csv", 'text/comma-separated-values'),
      :project => Project.first,
      :quotes_type => '"'
      )
    puts expense_import.errors.full_messages.join("\n") unless expense_import.valid?
    assert_difference('Expense.count', 1, 'Should have 1 expense in the database') do
      assert_equal 1, expense_import.imported_instances.count, 'Should find 1 expense in file'
      assert expense_import.save, 'Should save successfully'
    end
  end
end
