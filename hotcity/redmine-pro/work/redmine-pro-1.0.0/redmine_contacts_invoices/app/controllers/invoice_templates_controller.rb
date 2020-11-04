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

class InvoiceTemplatesController < ApplicationController
  unloadable

  menu_item :invoices

  before_action :find_invoice_template, :except => [:new, :create, :index]
  before_action :find_optional_project, :only => [:new, :create, :add, :destroy, :edit, :update]
  before_action :require_admin, :only => [:index]

  accept_api_auth :index

  include InvoicesHelper
  helper :invoices

  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    scope = InvoiceTemplate.visible
    scope = scope.in_project_or_public(@project) if @project

    @invoice_template_count = scope.count
    @invoice_template_pages = Paginator.new @invoice_template_count, @limit, params['page']
    @offset ||= @invoice_template_pages.offset
    @invoice_templates = scope.limit(@limit).offset(@offset).order("#{InvoiceTemplate.table_name}.name").all

    respond_to do |format|
      format.html
    end
  end

  def new
    @invoice_template = InvoiceTemplate.new
    @invoice_template.author = User.current
    @invoice_template.project = @project
  end

  def create
    @invoice_template = InvoiceTemplate.new
    @invoice_template.safe_attributes = params[:invoice_template]
    @invoice_template.author = User.current
    @invoice_template.project = params[:invoice_template_is_for_all] ? nil : @project

    if @invoice_template.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_project_or_global
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def preview
    old_setting = Setting.plugin_redmine_contacts_invoices['per_invoice_templates']
    Setting.plugin_redmine_contacts_invoices['per_invoice_templates'] = 1
    @invoice = Invoice.visible.first
    @invoice.template = @invoice_template
    send_data(invoice_to_pdf(@invoice), :type => 'application/pdf', :filename => 'invoice-preview.pdf', :disposition => 'inline')
  ensure
    Setting.plugin_redmine_contacts_invoices['per_invoice_templates'] = old_setting
  end

  def update
    @invoice_template.safe_attributes = params[:invoice_template]
    @invoice_template.project = nil if params[:invoice_template_is_for_all]

    if @invoice_template.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_project_or_global
    else
      render :action => 'edit'
    end
  end

  def destroy
    @invoice_template.destroy
    redirect_to_project_or_global
  end

  private

  def redirect_to_project_or_global
    redirect_to @project ? settings_project_path(@project, :tab => 'invoice_templates') : path_to_global_setting
  end

  def path_to_global_setting
    {
      :action => 'plugin',
      :id => 'redmine_contacts_invoices',
      :controller => 'settings',
      :tab => 'invoice_templates'
    }
  end

  def find_invoice_template
    @invoice_template = InvoiceTemplate.find(params[:id])
    @project = @invoice_template.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
