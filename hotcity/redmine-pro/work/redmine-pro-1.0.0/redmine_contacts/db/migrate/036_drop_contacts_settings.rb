# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class DropContactsSettings < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  class ::OldContactsSettings < ActiveRecord::Base
    self.table_name = 'contacts_settings'

    def self.convert
      setting = Setting.where(name: 'plugin_redmine_contacts').first || Setting.new(name: 'plugin_redmine_contacts')
      values = { projects: {} }

      project_ids = pluck(:project_id).uniq
      project_ids.each do |pid|
        values[:projects][pid] = {} unless values[:projects][pid]
        where(project_id: pid).each { |cs| values[:projects][pid][cs.name] = cs.value }
      end

      setting.value = setting.value ? setting.value.merge(values) : values
      setting.save
    end
  end

  def self.up

    ::OldContactsSettings.convert
    drop_table :contacts_settings
  end

  def self.down
    create_table :contacts_settings do |t|
      t.column :name, :string
      t.column :value, :text
      t.column :project_id, :integer
      t.column :updated_on, :datetime
    end
    add_index :contacts_settings, :project_id
  end
end
