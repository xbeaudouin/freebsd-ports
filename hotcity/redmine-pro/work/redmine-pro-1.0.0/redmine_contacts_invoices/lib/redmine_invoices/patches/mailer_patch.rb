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

module RedmineInvoices
  module Patches
    module MailerPatch
      module InstanceMethods
        def invoice_comment_added(object = User.current, comment = nil)
          comment = object if object.is_a?(Comment) && comment.nil?
          invoice = comment.commented
          redmine_headers 'Project' => invoice.project.identifier
          @author = comment.author
          message_id comment
          @invoice = invoice
          @comment = comment
          @invoice_url = url_for(:controller => 'invoices', :action => 'show', :id => invoice)
          mail :to => invoice.notified_users.collect(&:mail),
               :cc => invoice.notified_watchers.collect(&:mail),
               :subject => "Re: [#{invoice.project.name}] #{l(:label_invoice_comment_added)}: #{invoice.subject}"
        end
      end

      module ClassMethods
        def deliver_invoice_comment_added(comment)
          invoice_comment_added(User.current, comment).deliver_later
        end
      end

      def self.included(receiver)
        receiver.send :include, InstanceMethods
        receiver.extend(ClassMethods)
        receiver.class_eval do
          unloadable
        end
      end
    end
  end
end

unless Mailer.included_modules.include?(RedmineInvoices::Patches::MailerPatch)
  Mailer.send(:include, RedmineInvoices::Patches::MailerPatch)
end
