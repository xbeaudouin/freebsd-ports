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

if Redmine::VERSION.to_s >= '3.4' || RedmineContacts.unstable_branch?
  require 'redmine/wiki_formatting/textile/redcloth3'
else
  require 'redcloth3'
end

module RedmineInvoices
  class InvoiceFormater < RedCloth3
    RULES = [:textile, :markdown, :block_htmlite_new_line]

    def to_html(*_rules)
      super(*RULES).to_s
    end

    private

    def block_htmlite_new_line(text)
      text.gsub!(/\n/, '<br />')
    end
  end
end
