# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class ContactsBulkMailer < ActionMailer::Base
  include Redmine::I18n

  class UnauthorizedAction < StandardError; end
  class MissingInformation < StandardError; end

  helper :application

  def self.default_url_options
    h = Setting.host_name
    h = h.to_s.gsub(%r{\/.*$}, '') unless Redmine::Utils.relative_url_root.blank?
    { :host => h, :protocol => Setting.protocol }
  end

  def bulk_mail(contact, params = {})
    raise l(:error_empty_email) if (contact.emails.empty? || params[:message].blank?)

    @contact = contact
    @params = params

    p_attachments = params[:attachments]
    p_attachments = p_attachments.to_unsafe_hash if p_attachments.respond_to?(:to_unsafe_hash)
    p_attachments.each_value do |mail_attachment|
      if file = mail_attachment['file']
        file.rewind if file
        attachments[file.original_filename] = file.binread
        file.rewind if file
      elsif token = mail_attachment['token']
        if token.to_s =~ /^(\d+)\.([0-9a-f]+)$/
          attachment_id, attachment_digest = $1, $2
          if a = Attachment.where(:id => attachment_id, :digest => attachment_digest).first
            attachments[a.filename] = File.binread(a.diskfile)
          end
        end
      end
    end unless p_attachments.blank?

    mail(from: params[:from] || User.current.mail,
         to: contact.emails.first,
         cc: params[:cc],
         bcc: params[:bcc],
         subject: params[:subject]) do |format|
      format.text
      format.html
    end
  end
end
