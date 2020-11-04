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

requires_redmine_crm version_or_higher: '0.0.53' rescue raise "\n\033[31mRedmine requires newer redmine_crm gem version.\nPlease update with 'bundle update redmine_crm'.\033[0m"

INVOICES_VERSION_NUMBER = '4.2.3'
INVOICES_VERSION_TYPE = "PRO version"


Redmine::Plugin.register :redmine_contacts_invoices do
  name "Redmine Invoices plugin (#{INVOICES_VERSION_TYPE})"
  author 'RedmineUP'
  description 'Plugin for track invoices and expenses'
  version INVOICES_VERSION_NUMBER
  url 'https://www.redmineup.com/pages/plugins/invoices'
  author_url 'mailto:support@redmineup.com'

  requires_redmine :version_or_higher => '2.6'

  begin
    requires_redmine_plugin :redmine_contacts, version_or_higher: '4.1.4'
  rescue Redmine::PluginNotFound  => e
    raise "Please install redmine_contacts plugin"
  end

  settings :default => {
    :invoices_company_name => "Your company name",
    :invoices_company_representative => "Company representative name",
    :invoices_template  => "classic",
    :invoices_line_grouping => 0,
    :invoices_cross_project_contacts => true,
    :invoices_number_format => '#INV/%%YEAR%%%%MONTH%%%%DAY%%-%%ID%%',
    :invoices_company_info => "Your company address\nTax ID\nphone:\nfax:",
    :invoices_company_logo_url => "http://www.redmine.org/attachments/3458/redmine_logo_v1.png",
    :invoices_bill_info => "Your billing information (Bank, Address, IBAN, SWIFT & etc.)",
    :invoices_units  => "hours\ndays\nservice\nproducts"
  }, :partial => 'settings/invoices/invoices'


  project_module :contacts_invoices do
    hash = {
      invoices: [:index, :show, :context_menu],
      recurring_invoices: [:index, :show, :context_menu],
      invoice_payments: [:index, :show],
      invoice_reports: [:new, :autocomplete, :create, :preview]
    }

    permission :view_invoices, hash, read: true
    permission :add_invoices, :invoices => [:new, :create, :recurring]
    permission :edit_invoices, :invoices => [:new, :create, :edit, :update, :bulk_update],
                               :invoice_time_entries => [:new]
    permission :edit_own_invoices, :invoices => [:new, :create, :edit, :update, :delete]
    permission :delete_invoices, :invoices => [:destroy, :bulk_destroy]
    permission :comment_invoices,  :invoice_comments => :create
    permission :edit_invoice_payments,  :invoice_payments => [:new, :create, :destroy]
    permission :save_invoices_queries, {}, :require => :loggedin
    permission :manage_public_invoices_queries, {}, :require => :member
    permission :manage_invoices, :projects => :settings, :contacts_settings => :save, :invoice_comments => :destroy,
                                 :invoice_templates => [:new, :create, :edit, :update, :destroy]
    permission :import_invoices, { :invoice_imports => [:new, :create, :show, :settings, :mapping, :run] }
    permission :send_invoices, {:invoice_mails => [:new, :send_mail, :preview_mail]}
  end
  project_module :contacts_expenses do
    permission :view_expenses, {:expenses => [:index, :show, :context_menu]}, :read => true
    permission :add_expenses, :expenses => [:new, :create]
    permission :edit_expenses, :expenses => [:new, :create, :edit, :update, :bulk_update]
    permission :edit_own_expenses, :expenses => [:new, :create, :edit, :update, :delete, :bulk_update]
    permission :delete_expenses, :expenses => [:destroy, :bulk_destroy]
    permission :import_expenses, :expense_imports => [:new, :create, :show, :settings, :mapping, :run]
    permission :save_expenses_queries, {}, :require => :loggedin
    permission :manage_public_expenses_queries, {}, :require => :member
  end

  menu :top_menu, :invoices, {:controller => 'invoices', :action => 'index', :project_id => nil}, :caption => :label_invoice_plural, :if => Proc.new {
    User.current.allowed_to?({:controller => 'invoices', :action => 'index'}, nil, {:global => true}) && RedmineInvoices.settings['invoices_show_invoices_in_top_menu']
  }

  menu :application_menu, :invoices,
                          {:controller => 'invoices', :action => 'index'},
                          :caption => :label_invoice_plural,
                          :param => :project_id,
                          :if => Proc.new{User.current.allowed_to?({:controller => 'invoices', :action => 'index'},
                                          nil, {:global => true}) && RedmineInvoices.settings['invoices_show_in_app_menu']}
  menu :top_menu, :expenses, {:controller => 'expenses', :action => 'index', :project_id => nil}, :caption => :label_expense_plural, :if => Proc.new {
    User.current.allowed_to?({:controller => 'expenses', :action => 'index'}, nil, {:global => true}) && RedmineInvoices.settings['invoices_show_expenses_in_top_menu']
  }


  menu :application_menu, :expenses,
                          {:controller => 'expenses', :action => 'index'},
                          :caption => :label_expense_plural,
                          :param => :project_id,
                          :if => Proc.new{User.current.allowed_to?({:controller => 'expenses', :action => 'index'},
                                          nil, {:global => true}) && RedmineInvoices.settings['invoices_show_expenses_in_app_menu']}

  menu :project_menu, :expenses, {:controller => 'expenses', :action => 'index'}, :caption => :label_expense_plural, :param => :project_id

  activity_provider :expenses, :default => false, :class_name => ['Expense']

  menu :project_menu, :invoices, {:controller => 'invoices', :action => 'index'}, :caption => :label_invoice_plural, :param => :project_id

  menu :project_menu, :new_invoice, {:controller => 'invoices', :action => 'new'}, :caption => :label_invoice_new, :param => :project_id, :parent => :new_object

  menu :admin_menu, :invoices, {:controller => 'settings', :action => 'plugin', :id => "redmine_contacts_invoices"}, :caption => :label_invoice_plural, :param => :project_id, :html => {:class => 'icon'}

  activity_provider :invoices, :default => false, :class_name => ['InvoicePayment', 'Invoice']

  Redmine::Search.map do |search|
    search.register :invoices
    search.register :expenses
  end

end

require 'redmine_invoices'
