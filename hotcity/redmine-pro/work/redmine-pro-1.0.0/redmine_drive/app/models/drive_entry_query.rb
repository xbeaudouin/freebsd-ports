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

class DriveEntryQuery < Query
  self.queried_class = DriveEntry
  self.view_permission = :view_drive_entries if Redmine::VERSION.to_s >= '3.4'

  operators_by_filter_type[:drive_entry_tags] = operators_by_filter_type[:list]

  class QueryMultipleValuesColumn < QueryColumn
    def value_object(object)
      value = super
      value.respond_to?(:to_a) ? value.to_a : value
    end
  end

  self.available_columns = [
    QueryColumn.new(:filename, sortable: "#{DriveEntry.table_name}.name", frozen: true),
    QueryColumn.new(:size, sortable: "#{Attachment.table_name}.filesize", caption: :field_filesize),
    QueryColumn.new(:created_at, sortable: "#{DriveEntry.table_name}.created_at", default_order: 'desc', caption: :field_created_on),
    QueryColumn.new(:project, sortable: "#{Project.table_name}.id"),
    QueryColumn.new(:downloads, sortable: "#{Attachment.table_name}.downloads", caption: :label_downloads_abbr),
    QueryColumn.new(:author, sortable: lambda { User.fields_for_order_statement('users') }),
    QueryColumn.new(:description),
    QueryMultipleValuesColumn.new(:tags, caption: :label_drive_tags),
    QueryColumn.new(:updated_at, sortable: "#{DriveEntry.table_name}.updated_at", default_order: 'desc', caption: :field_updated_on)
  ]

  # Scope of queries that are global or on the given project
  scope :global_or_on_project, lambda { |project|
    where(project_id: (project.nil? ? nil : [nil, project.id]))
  }

  scope :sorted, lambda { order(:name, :id) }

  def initialize(attributes = nil, *args)
    super attributes
    self.filters ||= {}
  end

  def initialize_available_filters
    add_available_filter 'name', type: :text
    add_available_filter 'filesize', type: :float
    add_available_filter 'created_at', type: :date_past, label: :field_created_on
    add_available_filter 'tags', type: :drive_entry_tags, label: :label_drive_tags,
                         values: DriveEntry.available_tags.map { |t| [t.name, t.name] }

    add_available_filter 'author_id', type: :list, values: values_for_author_filter
    add_available_filter 'description', type: :text

    add_available_filter 'shared', type: :list, label: :label_drive_shared,
                         values: [[l(:general_text_yes), '1'], [l(:general_text_no), '0']]

    add_available_filter 'downloads', type: :integer

    add_available_filter 'updated_at', type: :date_past, label: :field_updated_on
  end

  def default_columns_names
    @default_columns_names ||= [:filename, :tags, :updated_at, :size, :downloads, :author]
  end

  def default_sort_criteria
    []
  end

  def public_columns
    columns = [:filename, :size]
    columns << :description
    columns.collect { |name| available_columns.find { |col| col.name == name } }
  end

  def css_classes
    s = sort_criteria.first
    if s.present?
      key, asc = s
      "sort-by-#{key.to_s.dasherize} sort-#{asc}"
    end
  end

  def is_private?
    visibility == VISIBILITY_PRIVATE
  end

  def base_scope(options = {})
    scope = DriveEntry.eager_load(:project)

    scope =
      if Redmine::VERSION.to_s < '3.0'
        scope.joins("LEFT OUTER JOIN #{Attachment.table_name} ON #{Attachment.table_name}.container_id = #{DriveEntry.table_name}.id AND #{Attachment.table_name}.container_type = 'DriveEntry'")
      else
        scope.includes(:attachment, :author, :parent, :children, :viewings)
      end

    scope.where(statement)
  end

  def drive_entries(options = {})
    scope = base_scope(options).order(options[:order])
    scope = scope.visible unless options[:public]
    if options[:search].blank?
      scope = scope.where(parent_id: options[:parent_id])
                .where(project_id: options[:project_id] || project.try(:id))
    else
      options[:search].split(' ').each do |search_string|
        scope = scope.live_search(search_string)
      end
    end

    scope = scope.limit(options[:limit]) if options[:limit].present?
    custom_sort(scope)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
  def sql_for_tags_field(_field, _operator, value)
    compare = operator_for('tags').eql?('=') ? 'IN' : 'NOT IN'
    drive_entry_ids = DriveEntry.tagged_with(value).map(&:id).join(',')
    "(#{DriveEntry.table_name}.id #{compare} (#{drive_entry_ids}))"
  end

  def sql_for_filesize_field(field, operator, value)
    slq_for_files(sql_for_field(field, operator, value, Attachment.table_name, field))
  end

  def sql_for_downloads_field(_field, operator, value)
    if operator == '*'
      return slq_for_files('1=1')
    elsif operator == '!*'
      return slq_for_files("(#{DriveEntry.table_name}.id NOT IN (SELECT viewed_id FROM viewings))")
    end

    compare_sql =
      case operator
      when '><'
        "BETWEEN #{value[0].to_i} AND #{value[1].to_i}"
      else
        "#{operator} #{value.first}"
      end

    drive_entry_ids =
      if compare_sql
        ActiveRecord::Base.connection.execute(<<-SQL.squish).map { |row| row.is_a?(Array) ? row[0] : row['viewed_id'] }
          SELECT viewed_id, COUNT(*) as downloads
          FROM viewings
          GROUP BY viewed_id
          HAVING COUNT(*) #{compare_sql}
        SQL
      end

    condition =
      if drive_entry_ids.any?
        "#{DriveEntry.table_name}.id IN (#{drive_entry_ids.join(',')})"
      else
        '1=0'
      end

    if value.first.to_i.zero? || operator == '<='
      condition << " OR #{DriveEntry.table_name}.id NOT IN (SELECT viewed_id FROM viewings)"
    end

    slq_for_files condition
  end

  private

  def slq_for_files(condition)
    "(#{Attachment.table_name}.id IS NOT NULL) AND (#{condition})"
  end

  def sort_criteria_first_key
    @sort_criteria_first_key =
      if sort_criteria.respond_to?(:first_key)
        sort_criteria.first_key
      else
        sort_criteria.first.try(:first)
      end
  end

  def first_asc?
    return sort_criteria.first_asc? if sort_criteria.respond_to?(:first_asc?)

    sort_criteria.present? && sort_criteria.first.try(:last) == 'asc'
  end

  def custom_sort(drive_entries)
    drive_entries = sort_by_size(drive_entries) if sort_criteria_first_key == 'size'
    drive_entries = sort_by_downloads(drive_entries) if sort_criteria_first_key == 'downloads'
    group_by_entry_type(drive_entries)
  end

  def group_by_entry_type(drive_entries)
    groups = drive_entries.group_by(&:entry_type)
    groups[:folder].to_a + groups[:file].to_a
  end

  def sort_by_size(drive_entries)
    drive_entries.sort do |a, b|
      first_asc? ? a.size <=> b.size : b.size <=> a.size
    end
  end

  def sort_by_downloads(drive_entries)
    drive_entries.sort do |a, b|
      if first_asc?
        a.view_count <=> b.view_count
      else
        b.view_count <=> a.view_count
      end
    end
  end

  def principals
    @principal ||= begin
      principals = []
      if project
        principals += Principal.member_of(project)
        unless project.leaf?
          principals += Principal.member_of(project.descendants.visible.all)
        end
      else
        principals += Principal.member_of(all_projects)
      end
      principals.uniq!
      principals.sort!
      principals.reject! { |p| p.is_a?(GroupBuiltin) }
      principals
    end
  end

  def users
    principals.select { |p| p.is_a?(User) }
  end

  def values_for_author_filter
    return author_values if respond_to?(:author_values)

    author_values = []
    author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    author_values += users.collect{|s| [s.name, s.id.to_s] }
    author_values
  end
end
