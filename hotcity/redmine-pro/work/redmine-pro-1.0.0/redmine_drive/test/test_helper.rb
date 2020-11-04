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

require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

def compatible_request(type, action, parameters = {})
  Rails.version < '5.1' ? send(type, action, parameters) : send(type, action, params: parameters)
end

def compatible_xhr_request(type, action, parameters = {})
  Rails.version < '5.1' ? xhr(type, action, parameters) : send(type, action, params: parameters, xhr: true)
end

def redmine_drive_fixtures_directory
  Redmine::Plugin.find(:redmine_drive).directory + '/test/fixtures/'
end

def set_redmine_drive_fixtures_attachments_directory
  Attachment.storage_path = redmine_drive_fixtures_directory + 'files'
end

def fixtures_class
  ActiveRecord::VERSION::MAJOR >= 4 ? ActiveRecord::FixtureSet : ActiveRecord::Fixtures
end

def create_fixtures(fixtures_directory, table_names, class_names = {})
  fixtures_class.create_fixtures(fixtures_directory, table_names, class_names)
end

def drive_entry_ids_in_list(selector = 'table.files tr[id^="drive-entry-"]')
  css_select(selector).map { |tag| tag['data-id'] || tag.data_id }
end

def drive_entries_in_list
  ids = drive_entry_ids_in_list
  RedmineDrive::VirtualFileSystem.find_drive_entries(ids).sort_by { |drive_entry| ids.index(drive_entry.id.to_s) }
end

def with_drive_settings(options, &block)
  saved_settings = options.keys.inject({}) do |h, k|
    h[k] = case RedmineDrive.settings[k]
           when Symbol, false, true, nil
             RedmineDrive.settings[k]
           else
             RedmineDrive.settings[k].dup
           end
    h
  end
  options.each { |k, v| RedmineDrive.settings[k] = v }
  yield
ensure
  saved_settings.each { |k, v| RedmineDrive.settings[k] = v } if saved_settings
end
