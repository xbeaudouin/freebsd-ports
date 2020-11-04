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
    module ApplicationControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          before_action :show_announcements, :except => [:download, :thumbnail, :contacts_thumbnail, :avatar], :if => proc { |_c| html? }
          helper :people
        end
      end

      module InstanceMethods
        private
        def html?
          request.format.html? || (!request.xhr? && !request.format.json? && !request.format.xml?)
        end

        def show_announcements
          return false unless RedminePeople.use_announcements?
          @today_announcements = PeopleAnnouncement.today
          changed_notes = has_change_announcements?(@today_announcements) || []
          @birthdays = { :x => [] }
          if RedminePeople.show_birthday_announcements? && User.current.allowed_people_to?(:view_people)
            @birthdays = {
              :label_people_birthday_today => Person.today_birthdays.first(8)
            }
            if @birthdays[:label_people_birthday_today].any?
              @birthdays[:label_people_birthday_tomorrow] = Person.tomorrow_birthdays.first(8)
              @birthdays[:label_people_birthday_this_week] = Person.week_birthdays.first(8)
            end
          end
          if ((cookies[:announcements_date] != Date.today.to_s &&
              (@today_announcements.present? || @birthdays.values.flatten.any?)) || changed_notes.present?) &&
              User.current.logged?
            cookies[:announcements_date] = Date.today.to_s
            @today_announcements = changed_notes if changed_notes.present?
            update_announcements_md5(@today_announcements)
          else
            @today_announcements = []
            @birthdays = nil
          end
        end

        def has_change_announcements?(notes)
          return false unless cookies[:announcements_md5]
          announcements_md5 = YAML::load cookies[:announcements_md5]
          notes.inject([]) do |answer, note|
            (answer << note) if Digest::MD5.hexdigest(note.description) != announcements_md5[note.id]
            answer
          end
        end

        def update_announcements_md5(notes)
          announcements_md5 = {}
          announcements_md5 = YAML::load cookies[:announcements_md5] if cookies[:announcements_md5]
          cookies[:birthdays_shown] = true
          notes.each do |note|
            announcements_md5[note.id] = Digest::MD5.hexdigest(note.description)
          end
          cookies[:announcements_md5] = YAML::dump(announcements_md5)
        end

        def set_person
          @person = Person.find(params[:person_id])
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end
    end
  end
end

unless ApplicationController.included_modules.include?(RedminePeople::Patches::ApplicationControllerPatch)
  ApplicationController.send(:include, RedminePeople::Patches::ApplicationControllerPatch)
end
