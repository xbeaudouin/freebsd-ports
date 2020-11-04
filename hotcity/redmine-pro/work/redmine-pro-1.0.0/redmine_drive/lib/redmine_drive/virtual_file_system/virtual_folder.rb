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
    class VirtualFolder
      include DriveEntryInterface
      include FolderInterface

      attr_reader :id, :name, :shared, :downloads, :description, :updated_at, :created_at
      attr_reader :project, :author, :tag_list

      def parent
        raise NotImplementedError
      end

      def children
        raise NotImplementedError
      end

      def entry_type
        :folder
      end

      def ancestors
        @ancestors ||= []
      end

      def children_by_query(query, options = {})
        query.drive_entries(options.merge(project_id: project_id))
      end

      def db_record_id
      end

      def project_id
        @project.try(:id)
      end

      def size
        @size ||= children.size
      end
    end
  end
end
