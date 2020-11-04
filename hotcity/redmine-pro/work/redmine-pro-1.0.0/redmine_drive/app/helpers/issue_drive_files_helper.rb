# encoding: utf-8
#
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

module IssueDriveFilesHelper
  include AttachmentsHelper
  include DriveEntriesHelper

  def filename_column_styles(_drive_entry, offset, _options = {})
    "padding-left: #{offset * 24}px;"
  end

  def filename_tag(drive_entry)
    send "#{drive_entry.entry_type}_name_content", drive_entry
  end

  def folder_name_content(folder, options = {})
    s = ''.html_safe
    s << expander_content(folder_children_url(folder)) if show_expander?(folder)
    s + link_to_folder(folder, options)
  end

  def file_name_content(file)
    check_box_tag('ids[]', file.id, false, id: nil) +
      content_tag(:span, file.filename, class: file.icon_classes, title: file.full_path)
  end

  def expander_content(url)
    content_tag :span, '&nbsp;'.html_safe,
                class: 'expander icon icon-collapsed',
                onclick: "toggleFolder(this, '#{url}');"
  end

  def link_to_folder(folder, options = {})
    url = search_issue_drive_files_path(current_folder_id: folder.id)
    link_to(
      options[:name] || folder.name,
      '#',
      class: options[:icon_classes] || folder.icon_classes || 'icon icon-folder',
      title: options[:title] || folder.full_path,
      onclick: "showFolderContent('#{url}'); return false;"
    )
  end

  def folder_children_url(folder)
    children_issue_drive_files_path(folder_id: folder.id, current_folder_id: @current_folder.id)
  end

  def css_classes(drive_entry)
    s = drive_entry.entry_type.to_s
    s << ' parent' if drive_entry.folder? && show_expander?(drive_entry)
    s
  end

  def show_expander?(folder)
    @search_string.blank? && folder.children.present?
  end

  def render_breadcrumbs
    folders = @current_folder.ancestors << @current_folder
    breadcrumb folders.inject([]) { |list, folder| list << link_to_folder(folder, icon_classes: '', title: folder.name) }
  end

  def shared_file_fields(shared_files)
    shared_files.map.with_index.inject({}) do |h, (file, index)|
      h[file.drive_entry.id] = shared_file_field(file, Time.now.to_i + index)
      h
    end
  end

  def shared_file_field(shared_file, child_index)
    fields_for(:issue, Issue.new) do |f|
      f.fields_for :shared_files, shared_file, child_index: child_index do |file_field|
        render partial: 'shared_file_field', locals: { f: file_field }
      end
    end
  end

  def link_to_attachment(attachment, options = {})
    return super unless @shared_file

    link_to options[:text] || @shared_file.filename,
            download_issue_drive_files_url(@shared_file, only_path: options[:only_path]),
            options.slice!(:only_path, :filename)
  end
end
