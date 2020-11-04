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

module RedmineDrive
  module Patches
    module IssuesControllerPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods

          before_action :save_shared_files_state, only: :update
        end
      end

      module InstanceMethods
        def save_shared_files_state
          @issue.save_shared_files_state
        end
      end
    end
  end
end

unless IssuesController.included_modules.include?(RedmineDrive::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineDrive::Patches::IssuesControllerPatch)
end
