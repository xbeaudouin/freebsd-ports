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

class CreateDriveEntries < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :drive_entries do |t|
      t.references :project, index: true, foreign_key: true
      t.references :parent, index: true
      t.integer :author_id, index: true, null: false
      t.string :name
      t.boolean :shared, default: false, null: false
      t.text :description
      t.timestamps null: false
    end

    if Rails.version < '4.2'
      add_index :drive_entries, :project_id
      add_index :drive_entries, :parent_id
      add_index :drive_entries, :author_id
    else
      add_foreign_key :drive_entries, :users, column: :author_id
    end
  end
end
