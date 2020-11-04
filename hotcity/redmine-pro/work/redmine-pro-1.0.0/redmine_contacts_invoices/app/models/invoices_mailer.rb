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

class InvoicesMailer < ActionMailer::Base
  unloadable

  include Redmine::I18n
  include InvoicesHelper
  helper :invoices

  InvoicesMailer.raise_delivery_errors = true

  def self.default_url_options
    { :host => Setting.host_name, :protocol => Setting.protocol }
  end

  def invoice(_user = User.current, invoice, options)
    @invoice = invoice
    @project = invoice.project
    recipients = options[:to].blank? ? invoice.contact.try(:primary_email) : options[:to].to_s
    from = options[:from].blank? ? InvoicesSettings.email_from_address : options[:from].to_s
    subject = options[:subject].blank? ? "#{l(:label_invoice)} #{invoice.number} (#{InvoicesSettings.email_subject_template || InvoicesSettings[:invoices_company_name, invoice.project]})" : options[:subject].to_s
    subject = Invoice.apply_invoice_macros(subject)
    @email_body = Invoice.apply_invoice_macros(options[:message].to_s)

    headers['X-Invoice-Id'] = invoice.number

    attachments[invoice.filename] = invoice_to_pdf(@invoice)

    options[:attachments].each do |index, mail_attachment|
      if file = mail_attachment['file']
        attachments[file.original_filename] = file.read
      elsif token = mail_attachment['token']
        if token.to_s =~ /^(\d+)\.([0-9a-f]+)$/
          attachment_id, attachment_digest = $1, $2
          if a = Attachment.where(:id => attachment_id, :digest => attachment_digest).first
            attachments[a.filename] = File.read(a.diskfile)
          end
        end
      end
    end unless options[:attachments].blank?

    mail :to => recipients,
         :from => from,
         :cc => options[:cc].to_s,
         :bcc => options[:bcc].to_s,
         :subject => subject
  end
  def recurring_notification(_user = User.current, invoice)
    return unless invoice.assigned_to
    @invoice = invoice
    @project = invoice.project
    recipient = invoice.assigned_to.mail
    from = InvoicesSettings.email_from_address
    subject = "#{l(:label_recurring_invoice)} #{invoice.number}"

    @email_body = invoice_url(invoice).to_s

    headers['X-Invoice-Id'] = invoice.number

    mail :to => recipient,
         :from => from,
         :subject => subject
  end
end
