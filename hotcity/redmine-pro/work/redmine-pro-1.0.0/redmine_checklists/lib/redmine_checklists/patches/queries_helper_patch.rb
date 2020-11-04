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

require_dependency 'queries_helper'

module RedmineChecklists
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods

          alias_method :column_value_without_checklists, :column_value
          alias_method :column_value, :column_value_with_checklists

          def render_checklist(checklists)
            content_tag :div, class: 'checklist' do
              checklists.map { |item| checklist_item_tag(item) }.join.html_safe
            end
          end

          def checklist_item_tag(item)
            s = item.is_section ? '' : check_box_tag('checklist_item', '', item.is_done, disabled: true)
            s << item.subject
            content_tag(:div, s.html_safe)
          end
        end
      end

      module InstanceMethods
        def column_value_with_checklists(column, item, value)
          if column.name == :checklist_relations && item.is_a?(Issue)
            render_checklist(value.to_a)
          else
            column_value_without_checklists(column, item, value)
          end
        end
      end
    end
  end
end

unless QueriesHelper.included_modules.include?(RedmineChecklists::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedmineChecklists::Patches::QueriesHelperPatch)
end
