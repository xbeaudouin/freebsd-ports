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

class InvoicePaymentsController < ApplicationController
  unloadable

  menu_item :invoices

  if InvoicesSettings.finance_plugin_installed?
    helper :operations
    include OperationsHelper
  end

  before_action :find_invoice_payments, only: [:index]
  before_action :find_invoice_payment_invoice, only: [:create, :new]
  before_action :find_invoice_payment, only: [:edit, :show, :destroy, :update]
  before_action :bulk_find_payments, only: [:bulk_update, :bulk_edit, :bulk_destroy, :context_menu]
  before_action :authorize, except: [:index, :edit, :update, :destroy]
  before_action :find_optional_project, only: [:index]

  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    respond_to do |format|
      format.api
    end
  end

  def new
    @invoice_payment = InvoicePayment.new(amount: @invoice.remaining_balance, payment_date: Date.today)
    if InvoicesSettings.finance_plugin_installed?
      @last_operation = @invoice.payments.last.try(:operation)
      @invoice_payment.assign_attributes(@last_operation.slice(:account_id, :category_id)) if @last_operation
    end
  end

  def create
    @invoice_payment = InvoicePayment.new
    @invoice_payment.safe_attributes = params[:invoice_payment]
    @invoice_payment.invoice = @invoice
    @invoice_payment.author = User.current
    if @invoice_payment.save
      Attachment.attach_files(@invoice_payment, (params[:attachments] || (params[:invoice_payment] && params[:invoice_payment][:uploads])))
      render_attachment_warning_if_needed(@invoice_payment)

      flash[:notice] = l(:notice_successful_create)

      respond_to do |format|
        format.html { redirect_to invoice_path(@invoice) }
        format.api  { render action: 'show', status: :created, location: invoice_payment_url(@invoice_payment) }
      end
    else
      respond_to do |format|
        format.html { render action: 'new' }
        format.api  { render_validation_errors(@invoice_payment) }
      end
    end
  end

  def destroy
    if @invoice_payment.can_be_destroyed? && @invoice_payment.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    respond_to do |format|
      format.html { redirect_to invoice_path(@invoice) }
      format.api  { head :ok }
    end
  end

  private

  def find_invoice_payments
    payments_scope = InvoicePayment.where({})
    payments_scope = payments_scope.where(invoice_id: params[:invoice_id]) if params[:invoice_id]
    payments_scope = payments_scope.where("#{InvoicePayment.table_name}.payment_date > ?", params[:date_from]) if params[:date_from]
    payments_scope = payments_scope.where("#{InvoicePayment.table_name}.payment_date <= ?", params[:date_to]) if params[:date_to]
    payments_scope = payments_scope.eager_load(:invoice).where(invoices: { contact_id: params[:contact_id] }) if params[:contact_id]
    payments_scope = payments_scope.where("LOWER(#{InvoicePayment.table_name}.description) LIKE ?", '%' + params[:description] + '%') if params[:description]
    payments_scope = payments_scope.where("#{InvoicePayment.table_name}.amount > ?", params[:amount_from]) if params[:amount_from]
    payments_scope = payments_scope.where("#{InvoicePayment.table_name}.amount <= ?", params[:amount_to]) if params[:amount_to]

    @limit =  per_page_option
    @offset = params[:page].to_i * @limit
    @payments_count = payments_scope.count
    @payments_pages = Paginator.new(self, @payments_count, @limit, params[:page])
    payments_scope = payments_scope.limit(@limit).offset(@offset)
    @invoice_payments = payments_scope
  end

  def find_invoice_payment_invoice
    invoice_id = params[:invoice_id] || (params[:invoice_payment] && params[:invoice_payment][:invoice_id])
    @invoice = Invoice.find(invoice_id)
    @project = @invoice.project
    project_id = params[:project_id] || (params[:invoice_payment] && params[:invoice_payment][:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoice_payment
    @invoice_payment = InvoicePayment.joins(invoice: :project).find(params[:id])
    @project ||= @invoice_payment.project
    @invoice ||= @invoice_payment.invoice
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
