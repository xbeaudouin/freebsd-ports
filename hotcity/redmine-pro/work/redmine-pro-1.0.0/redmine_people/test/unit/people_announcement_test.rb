# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class PeopleAnnouncementTest < ActiveSupport::TestCase
  fixtures :people_announcements

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_announcements])

  def test_once_announcements
    today_announcements = PeopleAnnouncement.today(people_announcements(:people_announcement_001).start_date)
    assert today_announcements.include?(people_announcements(:people_announcement_002))
    # and all created in this date
    assert today_announcements.include?(people_announcements(:people_announcement_001))
    assert today_announcements.include?(people_announcements(:people_announcement_003))
    assert today_announcements.include?(people_announcements(:people_announcement_004))
  end

  def test_every_day_announcements
    today_announcements = PeopleAnnouncement.today(people_announcements(:people_announcement_001).start_date + 1.day)
    assert today_announcements.include?(people_announcements(:people_announcement_001))
    assert !today_announcements.include?(people_announcements(:people_announcement_003))
    assert !today_announcements.include?(people_announcements(:people_announcement_004))
  end

  def test_every_week_announcements
    today_announcements = PeopleAnnouncement.today(people_announcements(:people_announcement_003).start_date + 1.week)
    assert today_announcements.include?(people_announcements(:people_announcement_003))
    assert today_announcements.include?(people_announcements(:people_announcement_001))
  end

  def test_every_month_announcements
    today_announcements = PeopleAnnouncement.today(people_announcements(:people_announcement_004).start_date + 1.month)
    assert today_announcements.include?(people_announcements(:people_announcement_004))
    assert today_announcements.include?(people_announcements(:people_announcement_001))
    assert !today_announcements.include?(people_announcements(:people_announcement_005)) # because 005 end date less then today
  end
end
