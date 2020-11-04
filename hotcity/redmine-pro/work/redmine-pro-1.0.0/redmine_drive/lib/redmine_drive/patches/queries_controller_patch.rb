# This file is a part of Redmin Drive (redmine_drive) plugin,
# Filse storage plugin for redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_drive is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_drive is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_drive.  If not, see <http://www.gnu.org/licenses/>.

module RedmineDrive
  module Patches
    module QueriesControllerPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods

          alias_method :current_menu_item_without_drive, :current_menu_item
          alias_method :current_menu_item, :current_menu_item_with_drive
        end
      end

      module InstanceMethods
        def current_menu_item_with_drive
          @query.is_a?(DriveEntryQuery) ? :drive : current_menu_item_without_drive
        end

        def redirect_to_drive_entry_query(options)
          redirect_to drive_entry_query_path(options)
        end

        def drive_entry_query_path(options)
          if @project.blank?
            drive_entries_path(options)
          else
            project_drive_entries_path(options.merge(project_id: @project))
          end
        end
      end
    end
  end
end

unless QueriesController.included_modules.include?(RedmineDrive::Patches::QueriesControllerPatch)
  QueriesController.send(:include, RedmineDrive::Patches::QueriesControllerPatch)
end
