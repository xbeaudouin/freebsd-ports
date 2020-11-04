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
    module IssuePatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods

          attr_accessor :old_shared_files

          if ActiveRecord::VERSION::MAJOR < 4
            has_many :shared_files, class_name: 'IssueDriveFile', dependent: :destroy,
                     order: 'created_at', include: { drive_entry: :attachment }
          else
            has_many :shared_files,
                     -> { includes(drive_entry: :attachment).order("#{IssueDriveFile.table_name}.created_at") },
                     class_name: 'IssueDriveFile', dependent: :destroy
          end

          accepts_nested_attributes_for :shared_files, allow_destroy: true,
                                        reject_if: proc { |attrs| attrs['drive_entry_id'].blank? }

          safe_attributes 'shared_files_attributes'
        end
      end

      module InstanceMethods
        def save_shared_files_state
          self.old_shared_files = shared_files.to_a
        end

        def update_shared_files_journal_details
          journal = init_journal User.current
          journal_history = JournalIssueDriveFilesHistory.new(old_shared_files, shared_files.to_a)
          if journal_history.diff
            journal.details << journal_history.journal_details
            journal.save
          end
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineDrive::Patches::IssuePatch)
  Issue.send(:include, RedmineDrive::Patches::IssuePatch)
end
