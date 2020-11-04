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

require_dependency 'issue'

module RedmineContacts
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
        end
      end

      class ContactsRelations < IssueRelation::Relations
        def to_s(*args)
          map(&:to_s).join(", ")
        end
      end

      class DealsRelations < IssueRelation::Relations
        def to_s(*args)
          map(&:to_s).join(", ")
        end
      end

      module InstanceMethods
        def reject_deal(attributes)
          exists = attributes['id'].present?
          empty = attributes[:deal_id].blank?
          attributes[:_destroy] = 1 if exists && empty
          !exists && empty
        end

        def related_custom_objects(klass)
          conditions = "#{CustomField.table_name}.type = 'IssueCustomField' AND #{CustomField.table_name}.field_format = '#{klass.to_s.downcase}'"
          conditions += id ? " AND #{CustomValue.table_name}.customized_id = #{id}" : " AND 1=0"
          klass.where(id: CustomValue.joins(:custom_field).where(conditions).pluck(:value).uniq)
        end

        def contacts_relations
          ContactsRelations.new(self, related_custom_objects(Contact).to_a)
        end

        def deas_relations
          DealsRelations.new(self, related_custom_objects(Deal).to_a)
        end

        def contacts
          related_custom_objects(Contact)
        end

        def deals
          related_custom_objects(Deal)
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineContacts::Patches::IssuePatch)
  Issue.send(:include, RedmineContacts::Patches::IssuePatch)
end
