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

class IssueDriveFilesController < ApplicationController
  menu_item :drive

  before_action :require_login, except: [:show, :download]

  before_action :find_current_folder, only: [:new, :search, :children]
  before_action :set_search_string, only: [:new, :search]
  before_action :find_drive_entries, only: [:new, :search]
  before_action :find_folder, only: :children

  before_action :find_optional_issue, only: :new
  before_action :find_issue, only: :create
  before_action :find_files, only: [:create, :add]
  before_action :build_shared_files, only: :add

  before_action :find_shared_file, only: [:show, :download, :destroy]
  before_action :file_readable, :read_authorize, only: [:show, :download]
  before_action :edit_authorize, only: [:create, :destroy]

  def show
    return download if Redmine::VERSION.to_s < '3.3'

    @attachment = @shared_file.attachment
    if @attachment.is_diff?
      @diff = File.read(@attachment.diskfile, mode: 'rb')
      @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
      @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)
      # Save diff type as user preference
      if User.current.logged? && @diff_type != User.current.pref[:diff_type]
        User.current.pref[:diff_type] = @diff_type
        User.current.preference.save
      end
      render 'attachments/diff'
    elsif @attachment.is_text? && @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
      @content = File.read(@attachment.diskfile, mode: 'rb')
      render 'attachments/file'
    elsif @attachment.is_image?
      render :image
    else
      render 'attachments/other'
    end
  end

  def download
    @shared_file.increment_downloads(request.remote_addr, User.current)
    attachment = @shared_file.attachment
    if stale?(etag: attachment.digest)
      send_file attachment.diskfile,
                filename: filename_for_content_disposition(attachment.filename),
                type: detect_content_type(attachment),
                disposition: 'attachment'
    end
  end

  def new
  end

  def create
    @issue.save_shared_files_state
    current_file_ids = @issue.shared_files.map(&:drive_entry_id)
    files = @files.reject { |file| current_file_ids.include?(file.id) }
    @issue.shared_files.create(files.map { |file| { issue: @issue, drive_entry: file } })
    @issue.update_shared_files_journal_details
    render partial: 'update_file_forms'
  end

  def add
  end

  def destroy
    @issue.save_shared_files_state
    @shared_file.issue.shared_files.destroy(@shared_file)
    @issue.update_shared_files_journal_details
    render partial: 'update_file_forms'
  end

  def search
    render partial: 'file_explorer', layout: false
  end

  def children
    @query = DriveEntryQuery.new(name: '_')

    render partial: 'children', locals: {
      query: @query,
      drive_entries: @folder.children_by_query(@query, order: 'drive_entries.name ASC'),
      parent: @folder,
      offset: @folder.offset_from(@current_folder)
    }
  end

  private

  def find_shared_file(id = params[:id])
    @shared_file = IssueDriveFile.includes(:issue, drive_entry: :attachment).find(id)
    @issue = @shared_file.issue
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue(id = params[:issue_id])
    @issue = Issue.find(id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_issue
    find_issue if params[:issue_id].present?
  end

  def find_files(ids = params[:ids])
    @files = DriveEntry.files.find(ids)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_folder(id = params[:folder_id])
    @folder = RedmineDrive::VirtualFileSystem.find_folder(id)
    @folder || render_404
  end

  def find_current_folder(id = params[:current_folder_id])
    @current_folder = RedmineDrive::VirtualFileSystem.find_current_folder(id)
    @current_folder || render_404
  end

  def set_search_string
    @search_string ||= (params[:q] || params[:term]).to_s.strip
  end

  def find_drive_entries
    @query = DriveEntryQuery.new(name: '_')
    if @query.valid?
      options = { order: 'drive_entries.name ASC', search: @search_string }
      options[:limit] = 50 if @search_string.present?
      @drive_entries = @current_folder.children_by_query(@query, options)
    end
  end

  def build_shared_files
    @shared_files = @files.map { |file| IssueDriveFile.new(issue: @issue, drive_entry: file) }
  end

  # Checks that the file exists and is readable
  def file_readable
    if @shared_file.attachment.readable?
      true
    else
      logger.error "Cannot send attachment, #{@shared_file.attachment.diskfile} does not exist or is unreadable."
      render_404
    end
  end

  def read_authorize
    @shared_file.visible? || deny_access
  end

  def edit_authorize
    User.current.allowed_to?(:edit_issues, @issue.project) || deny_access
  end

  def detect_content_type(attachment)
    content_type = attachment.content_type
    if content_type.blank? || content_type == 'application/octet-stream'
      content_type = Redmine::MimeType.of(attachment.filename)
    end
    content_type.to_s
  end
end
