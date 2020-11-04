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
  module VirtualFileSystem
    class ProjectFolder < VirtualFolder
      def initialize(project)
        @id = "project-folder-#{project.id}"
        @project = project
        @name = project.name

        @updated_at = project.updated_on
        @created_at = project.created_on

        @icon_classes = 'icon icon-project'
      end

      def ancestors
        @ancestors ||= [parent]
      end

      def parent
        @parent ||= VirtualFileSystem.root_folder
      end

      def children
        @children ||= project.drive_entries.root_drive_entries
      end

      def sub_folders
        @sub_folders ||= project.drive_entries.root_drive_entries.folders
      end
    end
  end
end
