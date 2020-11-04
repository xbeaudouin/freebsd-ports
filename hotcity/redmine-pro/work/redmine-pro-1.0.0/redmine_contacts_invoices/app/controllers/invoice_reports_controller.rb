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

class InvoiceReportsController < ApplicationController
  before_action :authorize_global, except: [:create, :preview]
  before_action :find_invoice, only: [:new, :create, :preview]
  before_action :find_invoice_templates, only: [:create, :preview]
  before_action :authorize_public, only: [:create, :preview]

  skip_before_action :check_if_login_required, only: [:create, :preview], if: :public_request?

  include InvoicesHelper

  def new
    @invoice_templates = invoice_templates
  end

  def create
    reports = @invoice_templates.map { |t| build_invoice_report(@invoice, t) }

    if reports.size > 1
      send_data RedmineInvoices.build_zip(reports), type: 'application/zip', filename: 'invoices reports.zip'
    else
      report = reports.first
      send_data report.content, type: 'application/pdf', filename: report.filename
    end
  end

  def autocomplete
    @invoice_templates = invoice_templates(params)
    render layout: false
  end

  def preview
    @reports = @invoice_templates.map { |t| build_invoice_report(@invoice, t, false) }

    options = @invoice.public_link_params(@invoice_templates)
    @public_link_url = preview_invoice_reports_path(options)
    @download_url = invoice_reports_path(options.merge(token: params[:token]))

    render layout: 'invoice_reports.pdf'
  end

  private

  def invoice_templates(options = {})
    scope = InvoiceTemplate.visible
    scope = scope.live_search(options[:q]) if options[:q].present?
    scope.to_a
  end

  def find_invoice
    @invoice = Invoice.find(params[:invoice_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoice_templates
    @invoice_templates = []
    if params[:invoice_template] && params[:invoice_template][:ids].present?
      @invoice_templates = InvoiceTemplate.find(params[:invoice_template][:ids])
    end

    if @invoice_templates.blank?
      flash[:error] = l(:label_invoice_templates_no_selected)
      redirect_to_referer_or { render html: l(:label_invoice_templates_no_selected), status: 200, layout: true }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def build_invoice_report(invoice, invoice_template, pdf = true)
    InvoiceReport.new(
      invoice_template.name,
      "#{invoice_template.name}.pdf",
      pdf ? invoice_to_pdf_wicked_pdf(invoice, invoice_template) : liquidize_invoice(invoice, invoice_template),
      invoice.public_link_params([invoice_template])
    )
  end

  def authorize_public
    return authorize_global unless public_request?
    InvoicesSettings.public_links? && valid_token? || render_403
  end

  def valid_token?
    params[:token] == @invoice.token_by(@invoice_templates.map(&:id))
  end

  def public_request?
    params.key? :token
  end
end
