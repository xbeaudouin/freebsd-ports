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
    module AttachmentsControllerPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods

          before_action :increment_drive_entry_download, only: :download

          alias_method :current_menu_item_without_drive, :current_menu_item
          alias_method :current_menu_item, :current_menu_item_with_drive
        end
      end

      module InstanceMethods
        def current_menu_item_with_drive
          if @attachment.try(:container).is_a?(DriveEntry)
            :drive
          else
            current_menu_item_without_drive
          end
        end

        def increment_drive_entry_download
          return unless @attachment.container.is_a?(DriveEntry)

          @attachment.container.view(request.remote_addr, User.current)
        end
      end
    end
  end
end

unless AttachmentsController.included_modules.include?(RedmineDrive::Patches::AttachmentsControllerPatch)
  AttachmentsController.send(:include, RedmineDrive::Patches::AttachmentsControllerPatch)
end
