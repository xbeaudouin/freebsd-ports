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

resources :invoices do
  member do
    get :client_view
  end
  collection do
    get :auto_complete
    get :bulk_edit, :context_menu
    post :bulk_edit, :bulk_update
    delete :bulk_destroy
    get :recurring
  end
  resources :invoice_mails, :only => [:new] do
    collection do
      post :send_mail, :preview_mail
    end
  end
end

resources :invoices do
  resources :invoice_payments, :as => :payments
end

resources :invoice_payments, :only => [:show, :index]
resources :projects do
  resources :invoice_templates, :only => [:new, :create]

  resources :invoice_imports, :only => [:new, :create, :show] do
    member do
      get :settings
      post :settings
      get :mapping
      post :mapping
      get :run
      post :run
    end
  end

  resources :expense_imports, :only => [:new, :create, :show] do
    member do
      get :settings
      post :settings
      get :mapping
      post :mapping
      get :run
      post :run
    end
  end
end

resources :invoice_templates do
  member do
    get :preview
  end
  collection do
    post :add
  end
end

resources :invoice_reports, only: [:new, :create] do
  collection do
    get :create
    get :autocomplete
    get :preview
  end
end

resources :expenses do
    collection do
      get :bulk_edit, :context_menu
      post :bulk_edit, :bulk_update
      delete :bulk_destroy
    end
end

resources :invoice_imports, :only => [:new, :create]
resources :expense_imports, :only => [:new, :create]
resources :invoice_comments, :only => [:create, :destroy]

resources :projects do
resources :invoices, :only => [:index, :new, :create]
  resources :expenses, :only => [:index, :new, :create]
end

match "invoice_time_entries/new", :controller => "invoice_time_entries", :action => 'new', :via => :get
match "invoice_time_entries/create", :controller => "invoice_time_entries", :action => 'create', :via => :post
