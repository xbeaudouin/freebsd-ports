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

class DriveEntry < ActiveRecord::Base
  include RedmineDrive::VirtualFileSystem::DriveEntryInterface
  include RedmineDrive::VirtualFileSystem::FolderInterface
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :author, class_name: 'User'

  belongs_to :parent, class_name: 'DriveEntry'
  has_many :children, class_name: 'DriveEntry', foreign_key: :parent_id, dependent: :destroy

  has_one :attachment, as: :container, dependent: :destroy

  has_many :issue_drive_files, dependent: :destroy
  rcrm_acts_as_taggable
  rcrm_acts_as_viewed

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name',
                  'shared',
                  'tag_list',
                  'description'

  attr_writer :parent_folder

  validates :author_id, :name, presence: true
  validate :check_storage_size_limit, on: :create, if: :file?
  validate :check_valid_name_in_folder

  scope :folders, lambda {
    where(<<-SQL.squish)
      #{DriveEntry.table_name}.id NOT IN (
        SELECT #{Attachment.table_name}.container_id
        FROM #{Attachment.table_name}
        WHERE #{Attachment.table_name}.container_type = 'DriveEntry'
      )
    SQL
  }

  scope :files, lambda {
    joins("INNER JOIN #{Attachment.table_name} ON #{Attachment.table_name}.container_id = #{DriveEntry.table_name}.id AND #{Attachment.table_name}.container_type = 'DriveEntry'")
  }

  scope :root_drive_entries, -> { where(parent_id: nil) }
  scope :global, -> { root_drive_entries.where(project_id: nil) }

  scope :visible, lambda { |*args|
    eager_load(:project)
      .where(DriveEntry.visible_condition(args.shift || User.current, *args))
  }
  scope :live_search, lambda { |search|
    where("LOWER(#{DriveEntry.table_name}.name) LIKE LOWER(?)", "%#{search}%")
  }

  def self.total_size
    files.sum("#{Attachment.table_name}.filesize").to_f
  end

  def self.visible_condition(user, options = {})
    <<-SQL.squish
      #{DriveEntry.table_name}.project_id IS NULL OR
        (#{Project.allowed_to_condition(user, :view_drive_entries, options)})
    SQL
  end
  def self.available_tags(options = {})
    scope = RedmineCrm::Tag.where({})
    project = options[:project]
    join = ["JOIN #{RedmineCrm::Tagging.table_name} ON #{RedmineCrm::Tagging.table_name}.tag_id = #{RedmineCrm::Tag.table_name}.id "]
    join << "JOIN #{table_name} ON #{table_name}.id = #{RedmineCrm::Tagging.table_name}.taggable_id
               AND #{RedmineCrm::Tagging.table_name}.taggable_type = #{quote_string_value(name)}"

    if attribute_names.include?('project_id') && project
      join << "JOIN #{Project.table_name} ON #{Project.table_name}.id = #{table_name}.project_id"
      scope = scope.where("#{table_name}.project_id = ?", project.id)
    else
      join << "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{table_name}.project_id"
    end

    if options[:name_like]
      scope = scope.where("LOWER(#{RedmineCrm::Tag.table_name}.name) LIKE LOWER(?)", "%#{options[:name_like]}%")
    end

    group_fields = ''
    group_fields << ", #{RedmineCrm::Tag.table_name}.created_at" if RedmineCrm::Tag.respond_to?(:created_at)
    group_fields << ", #{RedmineCrm::Tag.table_name}.updated_at" if RedmineCrm::Tag.respond_to?(:updated_at)

    scope = scope.joins(join.join(' '))
    scope = scope.where(visible_condition(User.current))
    scope = scope.select("#{RedmineCrm::Tag.table_name}.*, COUNT(DISTINCT #{RedmineCrm::Tagging.table_name}.taggable_id) AS count")
    scope = scope.group("#{RedmineCrm::Tag.table_name}.id, #{RedmineCrm::Tag.table_name}.name #{group_fields}")
    scope = scope.having('COUNT(*) > 0')
    scope = scope.order("#{RedmineCrm::Tag.table_name}.name")
    scope = scope.limit(options[:limit].to_i.zero? ? 30 : options[:limit].to_i)
    scope
  end

  def self.increment_files_downloads(drive_entries, ip, viewer = User.current)
    drive_entries.each do |drive_entry|
      if drive_entry.folder?
        increment_files_downloads(drive_entry.children, ip, viewer)
      else
        drive_entry.view(ip, viewer)
      end
    end
  end

  def self.update_drive_entries(drive_entries, params)
    params =
      if params.respond_to?(:transform_keys)
        params.transform_keys(&:to_i)
      else
        params.inject({}) { |h, (k, v)| h.merge(k.to_i => v) }
      end

    saved = true
    transaction do
      drive_entries.each do |drive_entry|
        if p = params[drive_entry.id]
          drive_entry.safe_attributes = p
          saved &&= drive_entry.save
          raise ActiveRecord::Rollback unless saved
        end
      end
    end
    saved
  end

  # Returns an unsaved copy of the drive entry
  def copy(attributes = nil)
    copy = self.class.new
    copy.attributes = self.attributes.dup.except('id', 'shared')
    copy.attachment = attachment.copy(container: copy) if file?
    copy.attributes = attributes if attributes
    copy
  end

  def basename
    File.basename(name, extname)
  end

  def extname
    File.extname(name)
  end

  def sub_folders
    @sub_folders ||= children.folders.includes(:children)
  end

  def children_by_query(query, options = {})
    query.drive_entries(options.merge(project_id: project_id, parent_id: id))
  end

  def entry_type
    @entry_type ||= attachment.blank? ? :folder : :file
  end

  def filename
    name.presence || attachment.try(:filename)
  end

  def size
    folder? ? children.size : attachment.filesize
  end

  def downloads
    view_count if file?
  end

  def description
    self['description'].presence || attachment.try(:description)
  end

  def ancestors
    @ancestors ||= begin
      values = []
      drive_entry = self
      while drive_entry.parent_id
        values.prepend(drive_entry.parent)
        drive_entry = drive_entry.parent
      end

      if project
        values.prepend(RedmineDrive::VirtualFileSystem::ProjectFolder.new(project))
      end

      values.prepend(RedmineDrive::VirtualFileSystem.root_folder)
    end
  end

  def attachments_visible?(user = User.current)
    user.allowed_to?(:view_drive_entries, self.project, global: true)
  end

  def public_link_token(timestamp = nil)
    Digest::MD5.hexdigest("#{id}/#{timestamp}/#{Rails.application.config.secret_token}")
      end

  def public_access_allowed?
    shared && (project.nil? || project.module_enabled?('drive'))
  end

  def increment_name
    self.name = "#{increment_basename}#{extname}"
  end

  def parent_folder
    @parent_folder ||= RedmineDrive::VirtualFileSystem.parent_for(self)
  end

  private

  def storage_size_limit_reached?
    RedmineDrive.storage_size &&
      (DriveEntry.total_size + size) > RedmineDrive.storage_size_in_bytes
  end

  def check_storage_size_limit
    errors.add(:size, :error_save_failed) if storage_size_limit_reached?
  end

  def check_valid_name_in_folder
    if name_changed? && !parent_folder.valid_name_of?(self)
      errors.add(:name, :error_file_already_exists, name: name)
    end
  end

  def increment_basename
    if (match_data = basename.match(/(?<name>.+)\s\((?<count>[1-9]\d*)\)$/))
      "#{match_data[:name]} (#{match_data[:count].to_i + 1})"
    else
      "#{basename} (1)"
    end
  end
end
