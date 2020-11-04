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

require_dependency 'application_helper'

module RedmineContacts
  module Patches
    module ApplicationHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          def stocked_reorder_link(object, name = nil, url = {}, method = :post)
            Redmine::VERSION.to_s > '3.3' ? reorder_handle(object, :param => name) : reorder_links(name, url, method)
          end

          alias_method :format_object_without_contact, :format_object
          alias_method :format_object, :format_object_with_contact
        end
      end

      module InstanceMethods
        def format_object_with_contact(object, html = true, &block)
          case object.class.name
          when 'CustomFieldValue', 'CustomValue'
            case object.custom_field.field_format
            when 'deal'
              Deal.where(id: object.value).map do |deal|
                html ? link_to_deal(deal) : deal.to_s
              end.join(', ').html_safe
            when 'contact'
              Contact.where(id: object.value).map do |contact|
                html ? contact_tag(contact) : contact.to_s
              end.join(', ').html_safe
            else
              format_object_without_contact(object, html, &block)
            end
          else
            format_object_without_contact(object, html, &block)
          end
        end
      end
    end
  end
end

unless ApplicationHelper.included_modules.include?(RedmineContacts::Patches::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedmineContacts::Patches::ApplicationHelperPatch)
end
