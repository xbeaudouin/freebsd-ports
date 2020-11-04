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

class ExpensesDrop < Liquid::Drop

  def initialize(expenses)
    @expenses = expenses
  end

  def before_method(id)
    expense = @expenses.where(:id => id).first || Expense.new
    ExpenseDrop.new expense
  end

  def all
    @all ||= @expenses.map do |expense|
      ExpenseDrop.new expense
    end
  end

  def visible
    @visible ||= @expenses.visible.map do |expense|
      ExpenseDrop.new expense
    end
  end

  def each(&block)
    all.each(&block)
  end

end


class ExpenseDrop < Liquid::Drop

  delegate :id, :expense_date, :description, :price, :price_to_s, :project, :status, :currency, :to => :@expense

  def initialize(expense)
    @expense = expense
  end

  def contact
    ContactDrop.new(@expense.contact) if @expense.contact
  end

  def custom_field_values
    @expense.custom_field_values
  end

end
