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

class DayoffsMailer < Mailer
  SENDING_METHOD = (Redmine::VERSION.to_s < '4.0' ? 'deliver' : 'deliver_later').freeze

  def dayoff_create(user, dayoff)
    @dayoff = dayoff
    mail to: user, subject: l(:label_people_added_day_off)
  end

  def self.deliver_dayoff_create(dayoff)
    dayoff.email_users.each do |user|
      dayoff_create(user, dayoff).send(SENDING_METHOD)
    end
  end
end
