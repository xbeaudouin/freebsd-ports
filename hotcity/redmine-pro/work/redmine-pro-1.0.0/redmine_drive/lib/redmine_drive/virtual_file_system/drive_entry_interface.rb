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
    module DriveEntryInterface
      def entry_type
        raise NotImplementedError
      end

      def ancestors
        raise NotImplementedError
      end

      def sub_folders
        raise NotImplementedError
      end

      def children_by_query(query, options = {})
        raise NotImplementedError
      end

      def folder?
        entry_type == :folder
      end

      def file?
        entry_type == :file
      end

      def db_record_id
        id
      end

      def offset_from(ancestor)
        ancestors.size - ancestors.map(&:id).index(ancestor.id) if descendant_of?(ancestor)
      end

      def descendant_of?(drive_entry)
        ancestors.map(&:id).include?(drive_entry.id) if drive_entry
      end

      def full_path
        ([ancestors.map(&:name)] << name).join('/')
      end

      def css_classes
        @css_classes ||= begin
          s = entry_type.to_s
          s << ' parent' if children.present?
          s
        end
      end

      def icon_classes
        @icon_classes ||=
          if folder?
            'icon icon-folder'
          else
            "icon icon-file #{Redmine::MimeType.css_class_of(name)}"
          end
      end
    end
  end
end
