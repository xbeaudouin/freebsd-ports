# This file is a part of Redmine Finance (redmine_finance) plugin,
# simple accounting plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_finance is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_finance is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_finance.  If not, see <http://www.gnu.org/licenses/>.

module RedmineFinance
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method :project_settings_tabs_without_finance, :project_settings_tabs
          alias_method :project_settings_tabs, :project_settings_tabs_with_finance
        end
      end

      module InstanceMethods
        # include ContactsHelper

        def project_settings_tabs_with_finance
          tabs = project_settings_tabs_without_finance
          return tabs unless User.current.allowed_to?(:edit_accounts, @project)
          tabs.push(:name => 'finance',
                    :action => :edit_accounts,
                    :partial => 'projects/finance_settings',
                    :label => :label_finance_plural)
          tabs
        end
      end
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineFinance::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineFinance::Patches::ProjectsHelperPatch)
end
