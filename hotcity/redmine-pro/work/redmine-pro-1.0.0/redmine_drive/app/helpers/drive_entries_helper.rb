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

module DriveEntriesHelper
  def drive_entry_column_content(column, drive_entry)
    if [:filename, :size, :description, :tags].include?(column.name)
      send "#{column.name}_column_content", column, drive_entry
    else
      column_content(column, drive_entry)
    end
  end

  def public_drive_entry_column_content(column, drive_entry)
    if column.name == :filename
      public_filename_column_content(drive_entry)
    else
      drive_entry_column_content(column, drive_entry)
    end
  end

  def drive_entry_column_styles(column, drive_entry, offset)
    return '' if column.name != :filename

    filename_column_styles(drive_entry, offset)
  end

  def filename_column_styles(drive_entry, offset, options = {})
    children = options[:only_folders] ? drive_entry.sub_folders : drive_entry.children
    "padding-left: #{(children.blank? ? 12 : 0) + offset * 16}px;"
  end

  def filename_column_content(_column, drive_entry)
    if User.current.allowed_to?(:edit_drive_entries, @project, global: true) && drive_entry.shared
      filename_tag(drive_entry) + ' ' + link_to_share_modal(drive_entry)
    else
      filename_tag(drive_entry)
    end
  end

  def filename_tag(drive_entry)
    if drive_entry.folder?
      folder_name_tag drive_entry
    else
      link_to_attachment drive_entry.attachment,
                         text: drive_entry.filename,
                         class: drive_entry.icon_classes,
                         title: drive_entry.full_path
    end
  end

  def link_to_share_modal(drive_entry)
    link_to '', share_modal_drive_entries_path(id: drive_entry, project_id: @project, current_folder_id: @current_folder.id),
            class: 'icon-only icon-link', rel: 'nofollow', remote: true
  end

  def public_filename_column_content(drive_entry)
    if drive_entry.folder?
      link_to(
        drive_entry.filename,
        drive_entry_url(@drive_entry, current_folder_id: drive_entry.id, token: params[:token], timestamp: params[:timestamp]),
        class: 'icon icon-folder'
      )
    else
      link_to(
        drive_entry.filename,
        download_drive_entries_path(ids: [drive_entry.id], id: @drive_entry, token: params[:token], timestamp: params[:timestamp]),
        class: 'icon icon-attachment'
      )
    end
  end

  def folder_name_tag(folder, options = {})
    options = { clickable: true, only_folders: false }.merge(options)
    url = options[:clickable] ? options[:url] || folder_path(folder) : '#'

    children = options[:only_folders] ? folder.sub_folders : folder.children
    if children.present?
      expander_url = options[:only_folders] ? sub_folders_url(folder) : folder_children_url(folder)
    end

    s = ''.html_safe
    s << expander_tag(expander_url) if expander_url && params[:search].blank?
    s + link_to(folder.name, url, class: folder.icon_classes || 'icon icon-folder', title: folder.full_path)
  end

  def folder_children_url(folder)
    children_drive_entries_path(project_id: @project, folder_id: folder.id, current_folder_id: @current_folder.id)
  end

  def sub_folders_url(folder)
    sub_folders_drive_entries_path(project_id: @project, folder_id: folder.id)
  end

  def expander_tag(url)
    content_tag :span, '&nbsp;'.html_safe,
                class: 'expander icon icon-collapsed',
                onclick: "toggleFolder(this, '#{url}');"
  end

  def folder_path(folder)
    folder_id = folder.id if folder.is_a?(DriveEntry)

    if folder.project_id
      project_drive_entries_path(project_id: folder.project, id: folder_id)
    elsif folder_id
      drive_entry_path(folder_id) # Path to a global folder
    else
      drive_entries_path # Path to root folder
    end
  end

  def size_column_content(_column, drive_entry)
    if drive_entry.folder?
      l(:label_drive_file_items, drive_entry.size)
    else
      number_to_human_size(drive_entry.size)
    end
  end

  def description_column_content(_column, drive_entry)
    drive_entry.description.to_s
  end

  def tags_column_content(_column, drive_entry)
    tag_links drive_entry.tag_list
  end

  def render_breadcrumbs
    folders = @current_folder.ancestors << @current_folder
    breadcrumb folders.inject([]) { |list, folder| list << link_to(folder.name, folder_path(folder)) }
  end

  def public_url_for(drive_entry, expiration_date = nil)
    timestamp = expiration_date.try(:to_s, :number)
    drive_entry_url(drive_entry, token: drive_entry.public_link_token(timestamp), timestamp: timestamp)
  end

  def drive_entry_query_links(title, queries)
    return '' if queries.empty?

    url_params = { controller: 'drive_entries', action: 'index', project_id: @project }

    queries_list = queries.map { |query|
      css = 'query'
      css << ' selected' if query == @query
      content_tag('li', link_to(query.name, url_params.merge(query_id: query), class: css))
    }.join("\n").html_safe

    content_tag('h3', title) + "\n" + content_tag('ul', queries_list, class: 'queries') + "\n"
  end

  def compatible_column_header(query, column, options = {})
    if Redmine::VERSION.to_s < '3.4'
      column_header(column)
    else
      column_header(query, column, options)
    end
  end

  def query_hidden_sort_tag(query)
    hidden_field_tag('sort', query.sort_criteria.to_param, id: nil)
  end

  # Returns the queries that are rendered in the sidebar
  def drive_sidebar_queries(project)
    scope = DriveEntryQuery.global_or_on_project(project).sorted
    scope = scope.visible if DriveEntryQuery.respond_to?(:visible)
    scope.to_a
  end

  def render_drive_sidebar_queries(project)
    queries = drive_sidebar_queries(project)

    out = ''.html_safe
    out << drive_entry_query_links(l(:label_my_queries), queries.select(&:is_private?))
    out << drive_entry_query_links(l(:label_query_plural), queries.reject(&:is_private?))
    out
  end

  def drive_entry_tag_url(tag_name)
    { controller: 'drive_entries',
      action: 'index',
      set_filter: 1,
      project_id: @project,
      current_folder_id: @current_folder.id,
      fields: [:tags],
      values: { tags: [tag_name] },
      operators: { tags: '=' } }
  end

  def tag_color(tag)
    "##{'%06x' % (tag.unpack('H*').first.hex % 0xffffff)}"
  end

  def tag_links(tag_list)
    return if tag_list.blank?

    content_tag :span, class: 'tag_list' do
      safe_join(tag_list.map { |tag| link_to tag, drive_entry_tag_url(tag) }, ', ')
    end
  end

  def shared_link_available?(drive_entries)
    result = drive_entries.size == 1
        result
  end

  def download_link_available?(drive_entries)
    return true
    drive_entries.size == 1 && @drive_entries.first.file?
  end
end
