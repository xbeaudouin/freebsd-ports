# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

require_dependency 'query'

module RedmineChecklists
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method :available_filters_without_checklists, :available_filters
          alias_method :available_filters, :available_filters_with_checklists

          add_available_column QueryColumn.new(:checklist_relations, caption: :field_checklist)
        end
      end

      module InstanceMethods

        def available_filters_with_checklists
          if @available_filters.blank?
            add_available_filter('checklists_status', :type => :list, :name => l(:label_checklist_status),
                                             :values => [[l(:label_checklist_status_done), '1'], [l(:label_checklist_status_undone), '0']]) unless available_filters_without_checklists.key?('checklists_status') && !User.current.allowed_to?(:view_checklists, project, :global => true)

            add_available_filter('checklists_item', :type => :string, :name => l(:label_checklist_item)) unless available_filters_without_checklists.key?('checklists_item') && !User.current.allowed_to?(:view_checklists, project, :global => true)
          else
            available_filters_without_checklists
          end
          @available_filters
        end

        def sql_for_checklists_status_field(_field, operator, value)
          case operator
          when '='
            compare = '='
          when '!'
            compare = '!='
          end

          condition =
            if value.size > 1
              '1=1'
            else
              is_done_val = value.join == '1' ? self.class.connection.quoted_true : self.class.connection.quoted_false
              "is_section = #{self.class.connection.quoted_false} AND is_done #{compare} #{is_done_val}"
            end

          issue_ids = "SELECT DISTINCT(#{Checklist.table_name}.issue_id) FROM #{Checklist.table_name} WHERE #{condition}"
          "(#{Issue.table_name}.id IN (#{issue_ids}))"
        end

        def sql_for_checklists_item_field(_field, operator, value)
          case operator
          when '=', '!'
            condition = "#{Checklist.table_name}.subject = ?"
          when '~', '!~'
            condition = "LOWER(#{Checklist.table_name}.subject) LIKE LOWER(?)"
            value = "%#{value.join}%"
          when '*', '!*'
            condition = '1=1'
          end
          issue_ids = Checklist.where(condition, value).pluck(:issue_id).uniq
          if ['!', '!~'].include?(operator)
            all_issue_ids = Checklist.pluck(:issue_id).uniq
            issue_ids = all_issue_ids - issue_ids
          end
          return '1=0' if issue_ids.empty?
          "(#{Issue.table_name}.id #{'NOT' if operator == '!*'} IN (#{issue_ids.join(',')}))"
        end
      end
    end
  end
end

if (ActiveRecord::Base.connection.tables.include?('queries') rescue false) &&
   IssueQuery.included_modules.exclude?(RedmineChecklists::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineChecklists::Patches::IssueQueryPatch)
end
