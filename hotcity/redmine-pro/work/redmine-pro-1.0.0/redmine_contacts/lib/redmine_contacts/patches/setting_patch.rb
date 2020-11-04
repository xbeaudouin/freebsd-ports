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

module RedmineContacts
  module Patches
    module SettingPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do
          class << self
            alias_method 'plugin_redmine_contacts=_without_contacts', :plugin_redmine_contacts=
            alias_method :plugin_redmine_contacts=, 'plugin_redmine_contacts=_with_contacts'
          end
        end
      end

      module ClassMethods
        define_method('plugin_redmine_contacts=_with_contacts') do |settings|
          updated_settings = plugin_redmine_contacts.merge(settings)
          send('plugin_redmine_contacts=_without_contacts', updated_settings)
        end
      end
    end
  end
end

unless Setting.included_modules.include?(RedmineContacts::Patches::SettingPatch)
  Setting.send(:include, RedmineContacts::Patches::SettingPatch)
end
