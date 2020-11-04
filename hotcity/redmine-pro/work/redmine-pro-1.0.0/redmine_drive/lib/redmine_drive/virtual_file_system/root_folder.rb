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
    class RootFolder < VirtualFolder
      include Redmine::I18n

      def initialize(name = l(:label_drive))
        @id = 'root-folder'
        @name = name
      end

      def parent
      end

      def children
        @children ||= VirtualFileSystem.project_folders + DriveEntry.global
      end

      def sub_folders
        @sub_folders ||= VirtualFileSystem.project_folders + DriveEntry.global.folders
      end

      def children_by_query(query, options = {})
        return super if options[:search].present? || query.filters.present?

        VirtualFileSystem.project_folders + super
      end
    end
  end
end
