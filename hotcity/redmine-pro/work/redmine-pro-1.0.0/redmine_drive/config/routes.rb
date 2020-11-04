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

resources :drive_entries, path: :drive, except: [:new, :create, :edit] do
  collection do
    get :tags_autocomplete
    get :context_menu
    get :download

    get :children
    get :sub_folders

    get :new_folder
    post :create_folder

    get :new_files
    post :create_files

    get :edit
    get :share_modal
    get :bulk_edit
    put :bulk_update

    get :copy_modal
    post :copy

    get :move_modal
    post :move
  end
end

match '/drive', controller: 'drive_entries', action: 'destroy', via: [:delete, :post]

get '/projects/:project_id/drive(/:id)', to: 'drive_entries#index', as: 'project_drive_entries'

resources :issue_drive_files, except: [:index, :edit, :update] do
  collection do
    get '/download/:id', to: 'issue_drive_files#download', id: /\d+/, as: 'download'
    get :search
    get :children
    post :add
  end
end
