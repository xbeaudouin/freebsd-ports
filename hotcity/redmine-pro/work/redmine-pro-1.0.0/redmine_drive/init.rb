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

requires_redmine_crm version_or_higher: '0.0.53' rescue raise "\n\033[31mRedmine requires newer redmine_crm gem version.\nPlease update with 'bundle update redmine_crm'.\033[0m"

require 'redmine'
require 'redmine_drive'

DRIVE_VERSION_NUMBER = '1.0.1'
DRIVE_VERSION_TYPE = "PRO version"

Redmine::Plugin.register :redmine_drive do
  name "Redmine Drive plugin (#{DRIVE_VERSION_TYPE})"
  author 'RedmineUP'
  description 'Store, share and access your files from any device'
  version DRIVE_VERSION_NUMBER
  url 'http://redmineup.com/pages/plugins/drive'
  author_url 'mailto:support@redmineup.com'

  requires_redmine version_or_higher: '2.6'

  settings default: {}, partial: 'settings/drive/index'

  project_module :drive do
    permission :view_drive_entries, { drive_entries: [:index, :show, :children, :sub_folders, :download, :context_menu] }
    permission :add_drive_entries, { drive_entries: [:new_folder, :create_folder, :new_files, :create_files, :copy_modal, :copy] }, require: :loggedin
    permission :edit_drive_entries, { drive_entries: [:edit, :update, :bulk_edit, :bulk_update, :destroy, :move_modal, :move, :share_modal] }, require: :loggedin
  end

  menu :top_menu, :drive, { controller: 'drive_entries', action: 'index', project_id: nil }, caption: :label_drive,
        if: Proc.new { User.current.allowed_to?({ controller: 'drive_entries', action: 'index' }, nil, global: true) }

  menu :application_menu, :drive, { controller: 'drive_entries', action: 'index' }, caption: :label_drive,
       if: Proc.new { User.current.allowed_to?({ controller: 'drive_entries', action: 'index' }, nil, global: true) }

  menu :project_menu, :drive, { controller: 'drive_entries', action: 'index' }, caption: :label_drive, param: :project_id
end
