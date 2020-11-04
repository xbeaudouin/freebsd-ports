# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

module RedminePeople
  module Patches
    module AutoCompletesControllerPatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods
        end
      end

      module InstanceMethods
        USERS_LIMIT = 10

        def people_users
          @users = User.active.sorted.like(params[:q]).limit(USERS_LIMIT)
          @users = @users.visible if Redmine::VERSION.to_s >= '3.0'
          @users = @users.to_a
          render layout: false
        end

        def people_tags
          options = {
            name_like: (params[:q] || params[:term]).to_s.strip,
            limit: params[:limit],
          }
          @people_tags = Person.available_tags(options)
          render layout: false, partial: 'people_tags'
        end
      end
    end
  end
end

unless AutoCompletesController.included_modules.include?(RedminePeople::Patches::AutoCompletesControllerPatch)
  AutoCompletesController.send(:include, RedminePeople::Patches::AutoCompletesControllerPatch)
end
