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

class CalendarPatchTest < ActiveSupport::TestCase
  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/', [:people_holidays])

  def setup
    @calendar = Redmine::Helpers::Calendar.new('2017-01-01'.to_date)
    @calendar.custom_events = PeopleHoliday.between('2017-01-01'.to_date, '2018-01-01'.to_date).to_a
  end
  def test_working_and_non_working_days_list
    check_working_and_non_working_days_cases [], [
      { from: '2017-03-27'.to_date, to: '2017-04-02'.to_date, non_working_days_list: ['2017-04-01'.to_date, '2017-04-02'.to_date] },
      { from: '2017-04-03'.to_date, to: '2017-04-09'.to_date, non_working_days_list: ['2017-04-03'].map(&:to_date) },
      { from: '2017-03-27'.to_date, to: '2017-03-31'.to_date, non_working_days_list: [] },
    ]

    check_working_and_non_working_days_cases %w(6 7), [
      { from: '2017-03-27'.to_date, to: '2017-04-02'.to_date, non_working_days_list: ['2017-04-01'.to_date, '2017-04-02'.to_date] },
      { from: '2017-04-03'.to_date, to: '2017-04-09'.to_date, non_working_days_list: ['2017-04-03', '2017-04-08', '2017-04-09'].map(&:to_date) },
      { from: '2017-03-27'.to_date, to: '2017-03-31'.to_date, non_working_days_list: [] }
    ]

    check_working_and_non_working_days_cases %w(3 7), [
      { from: '2017-03-27'.to_date, to: '2017-04-02'.to_date, non_working_days_list: ['2017-03-29', '2017-04-01', '2017-04-02'].map(&:to_date) },
      { from: '2017-04-03'.to_date, to: '2017-04-09'.to_date, non_working_days_list: ['2017-04-03', '2017-04-05', '2017-04-09'].map(&:to_date) },
      { from: '2017-03-27'.to_date, to: '2017-03-31'.to_date, non_working_days_list: ['2017-03-29'.to_date] }
    ]
  end

  private

  def check_working_and_non_working_days_cases(non_working_week_days, test_cases)
    with_settings non_working_week_days: non_working_week_days do
      test_cases.each do |data|
        assert_equal data[:non_working_days_list], @calendar.non_working_days_list(data[:from], data[:to])
        assert_equal (data[:from]..data[:to]).to_a - data[:non_working_days_list], @calendar.working_days_list(data[:from], data[:to])
      end
    end
  end
end
