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
    module IssuesHelperPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods

          alias_method :details_to_strings_without_drive, :details_to_strings
          alias_method :details_to_strings, :details_to_strings_with_drive

          def show_added_file_detail(file, exists, no_html = false, options = {})
            label = l(:label_drive_shared_file)
            value = file.filename

            unless no_html
              label = content_tag('strong', label)
              value =
                if exists
                  added_file_value file, options
                else
                  content_tag('i', h(value))
                end
            end

            l(:text_journal_added, label: label, value: value).html_safe
          end

          def added_file_value(file, options)
            value = link_to h(file.filename), issue_drive_file_url(file.id, only_path: options[:only_path])
            if options[:only_path] != false
              value += ' '
              value += link_to('', download_issue_drive_files_url(file.id, only_path: options[:only_path]),
                               class: 'icon-only icon-download', title: l(:button_download))
            end
            value
          end

          def show_removed_file_detail(file, no_html = false)
            label = l(:label_drive_shared_file)
            old_value = file.filename

            unless no_html
              label = content_tag('strong', label)
              old_value = content_tag('del') { content_tag('i', h(old_value)) }
            end

            l(:text_journal_deleted, label: label, old: old_value).html_safe
          end
        end
      end

      module InstanceMethods
        def details_to_strings_with_drive(details, no_html = false, options = {})
          details_shared_files, details_other = details.partition { |x| x.prop_key == 'shared_files' }
          strings = details_to_strings_without_drive(details_other, no_html, options)
          options[:only_path] = (options[:only_path] == false ? false : true)

          details_shared_files.each do |detail|
            diff = JournalIssueDriveFilesHistory.new(detail.old_value, detail.value).diff
            added = diff[:added].to_a
            removed = diff[:removed].to_a
            both_ids = (added + removed).map(&:id).uniq
            shared_file_ids = IssueDriveFile.where(id: both_ids).pluck(:id)

            added.each do |item|
              strings << show_added_file_detail(item, shared_file_ids.include?(item.id), no_html, options)
            end

            removed.each do |item|
              strings << show_removed_file_detail(item, no_html)
            end
          end

          strings
        end
      end
    end
  end
end

unless IssuesHelper.included_modules.include?(RedmineDrive::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineDrive::Patches::IssuesHelperPatch)
end
