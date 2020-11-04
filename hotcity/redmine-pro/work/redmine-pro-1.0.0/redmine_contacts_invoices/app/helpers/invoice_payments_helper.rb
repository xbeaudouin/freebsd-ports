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

module InvoicePaymentsHelper
  def options_for_accounts(invoice_payment, invoice)
    return [] unless InvoicesSettings.finance_plugin_installed?
    options_for_select([[]] + invoice.compatible_accounts.map { |acc| [acc.name, acc.id] },
                       invoice_payment.account_id)
  end

  def options_for_categories(invoice_payment)
    return [] unless InvoicesSettings.finance_plugin_installed?
    operation_category_tree_options_for_select(operation_categories_for_select, selected: OperationCategory.find_by(id: invoice_payment.category_id),
                                                                                include_blank: true)
  end

  def delete_confirmation(payment)
    return l(:text_are_you_sure) unless InvoicesSettings.finance_plugin_installed?
    payment.operation ? l(:label_invoices_linked_operation_are_you_sure) : l(:text_are_you_sure)
  end
end
