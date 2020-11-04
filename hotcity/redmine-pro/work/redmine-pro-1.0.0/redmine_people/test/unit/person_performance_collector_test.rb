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

class PersonPerformanceCollectorTest < ActiveSupport::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users, :projects, :issues, :roles, :members, :member_roles

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_information, :time_entries, :people_holidays])

  def setup
    @admin = User.find(1)
    @person = Person.find(4)
    User.current = @admin
    Setting.plugin_redmine_people = {}
  end

  def test_person_performance_metrics_with_different_workday_length_and_intervals_by_month
    with_app_settings([], 8) do
      check_performance_metrics '2017-01-15', @person, nil, '2017-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-02-15', @person, nil, '2017-01-01', metrics(0, 0, 0, 0)

      check_performance_metrics '2017-04-05', @person, nil, nil, metrics(23.75, 148.4375, 0.5, 7.25)
      check_performance_metrics '2017-04-05', @person, PersonPerformanceCollector::MONTH, nil, metrics(23.75, 148.4375, 0.5, 7.25)

      check_performance_metrics '2017-04-05', @person, nil, '2017-04-01', metrics(23.75, 148.4375, 0.5, 7.25)
      check_performance_metrics '2017-04-30', @person, nil, '2017-04-01', metrics(39, 18.055555555555557, 0.5, 7.25)
      check_performance_metrics '2017-09-01', @person, nil, '2017-04-01', metrics(39, 18.055555555555557, 0.5, 7.25)
      check_performance_metrics '2018-01-01', @person, nil, '2017-04-01', metrics(39, 18.055555555555557, 0.5, 7.25)
    end

    with_app_settings([], 6) do
      check_performance_metrics '2017-01-15', @person, nil, '2017-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-02-15', @person, nil, '2017-01-01', metrics(0, 0, 0, 0)

      check_performance_metrics '2017-04-05', @person, nil, nil, metrics(23.75, 197.91666666666666, 4.5, 7.25)
      check_performance_metrics '2017-04-05', @person, PersonPerformanceCollector::MONTH, nil, metrics(23.75, 197.91666666666666, 4.5, 7.25)

      check_performance_metrics '2017-04-05', @person, nil, '2017-04-01', metrics(23.75, 197.91666666666666, 4.5, 7.25)
      check_performance_metrics '2017-04-30', @person, nil, '2017-04-01', metrics(39, 24.074074074074073, 6.5, 7.25)
      check_performance_metrics '2017-09-01', @person, nil, '2017-04-01', metrics(39, 24.074074074074073, 6.5, 7.25)
      check_performance_metrics '2018-01-01', @person, nil, '2017-04-01', metrics(39, 24.074074074074073, 6.5, 7.25)
    end

    @person.information.workday_length = 7
    with_app_settings([], 8) do
      check_performance_metrics '2017-01-15', @person, nil, '2017-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-02-15', @person, nil, '2017-01-01', metrics(0, 0, 0, 0)

      check_performance_metrics '2017-04-05', @person, nil, nil, metrics(23.75, 169.64285714285714, 2.5, 7.25)
      check_performance_metrics '2017-04-05', @person, PersonPerformanceCollector::MONTH, nil, metrics(23.75, 169.64285714285714, 2.5, 7.25)

      check_performance_metrics '2017-04-05', @person, nil, '2017-04-01', metrics(23.75, 169.64285714285714, 2.5, 7.25)
      check_performance_metrics '2017-04-30', @person, nil, '2017-04-01', metrics(39, 20.634920634920636, 3.5, 7.25)
      check_performance_metrics '2017-09-01', @person, nil, '2017-04-01', metrics(39, 20.634920634920636, 3.5, 7.25)
      check_performance_metrics '2018-01-01', @person, nil, '2017-04-01', metrics(39, 20.634920634920636, 3.5, 7.25)
    end
  end if Rails.version >= '4.1' # travel_to helper added in Rails  4.1 (Redmine version >= 3.0)


  def test_person_performance_metrics_with_different_workday_length_and_intervals_by_year
    with_app_settings([], 8) do
      check_performance_metrics '2016-01-15', @person, PersonPerformanceCollector::YEAR, '2016-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-01-15', @person, PersonPerformanceCollector::YEAR, '2016-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-03-01', @person, PersonPerformanceCollector::YEAR, nil, metrics(0, 0, 0, 0)
      check_performance_metrics '2017-03-31', @person, PersonPerformanceCollector::YEAR, nil, metrics(36.5, 5.069444444444445, 1.5, 0)
    end

    with_app_settings([], 6) do
      check_performance_metrics '2016-01-15', @person, PersonPerformanceCollector::YEAR, '2016-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-01-15', @person, PersonPerformanceCollector::YEAR, '2016-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-03-01', @person, PersonPerformanceCollector::YEAR, nil, metrics(0, 0, 0, 0)
      check_performance_metrics '2017-03-31', @person, PersonPerformanceCollector::YEAR, nil, metrics(36.5, 6.7592592592592595, 6.5, 0)
    end

    @person.information.workday_length = 7
    with_app_settings([], 8) do
      check_performance_metrics '2016-01-15', @person, PersonPerformanceCollector::YEAR, '2016-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-01-15', @person, PersonPerformanceCollector::YEAR, '2016-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-03-01', @person, PersonPerformanceCollector::YEAR, nil, metrics(0, 0, 0, 0)
      check_performance_metrics '2017-03-31', @person, PersonPerformanceCollector::YEAR, nil, metrics(36.5, 5.7936507936507935, 2.75, 0)
    end
  end if Rails.version >= '4.1'


  def test_person_performance_metrics_with_specific_non_working_week_days_and_intervals_by_month
    with_app_settings(%w(3 7), 8) do
      check_performance_metrics '2017-01-15', @person, nil, '2017-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-02-15', @person, nil, '2017-01-01', metrics(0, 0, 0, 0)

      check_performance_metrics '2017-04-05', @person, nil, nil, metrics(23.75, 296.875, 0.5, 15.25)
      check_performance_metrics '2017-04-05', @person, PersonPerformanceCollector::MONTH, nil, metrics(23.75, 296.875, 0.5, 15.25)

      check_performance_metrics '2017-04-05', @person, nil, '2017-04-01', metrics(23.75, 296.875, 0.5, 15.25)
      check_performance_metrics '2017-04-30', @person, nil, '2017-04-01', metrics(39, 25.657894736842106, 0.5, 15.25)
      check_performance_metrics '2017-09-01', @person, nil, '2017-04-01', metrics(39, 25.657894736842106, 0.5, 15.25)
      check_performance_metrics '2018-01-01', @person, nil, '2017-04-01', metrics(39, 25.657894736842106, 0.5, 15.25)
    end
  end if Rails.version >= '4.1'

  def test_person_performance_metrics_with_specific_non_working_week_days_and_intervals_by_year
    with_app_settings(%w(3 7), 8) do
      check_performance_metrics '2016-01-15', @person, PersonPerformanceCollector::YEAR, '2016-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-01-15', @person, PersonPerformanceCollector::YEAR, '2016-01-01', metrics(0, 0, 0, 0)
      check_performance_metrics '2017-03-01', @person, PersonPerformanceCollector::YEAR, nil, metrics(0, 0, 0, 0)
      check_performance_metrics '2017-03-31', @person, PersonPerformanceCollector::YEAR, nil, metrics(36.5, 7.12890625, 1.5, 7)
    end
  end if Rails.version >= '4.1'

  def test_performance_histogram_chart_data
    with_people_settings 'workday_length' => 8 do
      check_performance_chart_data '2017-01-15', @person, nil, '2017-01-01', Array.new(15, { spent_time: 0.0, height_ratio: 0, performance: 0 })
      check_performance_chart_data '2017-02-15', @person, nil, '2017-01-01', Array.new(31, { spent_time: 0.0, height_ratio: 0, performance: 0 })
    end

    with_people_settings 'workday_length' => 8 do
      check_performance_chart_data '2017-04-05', @person, nil, nil, [
        { spent_time: 0.0, height_ratio: 0.0, performance: 0 },
        { spent_time: 0.0, height_ratio: 0.0, performance: 0 },
        { spent_time: 7.3, height_ratio: 0.8529411764705882, performance: 91 },
        { spent_time: 8.5, height_ratio: 1.0, performance: 106 },
        { spent_time: 8.0, height_ratio: 0.9411764705882353, performance: 100 }
      ]
    end

    with_people_settings 'workday_length' => 6 do
      check_performance_chart_data '2017-04-05', @person, nil, nil, [
        { spent_time: 0.0, height_ratio: 0.0, performance: 0 },
        { spent_time: 0.0, height_ratio: 0.0, performance: 0 },
        { spent_time: 7.3, height_ratio: 0.8529411764705882, performance: 122 },
        { spent_time: 8.5, height_ratio: 1.0, performance: 142 },
        { spent_time: 8.0, height_ratio: 0.9411764705882353, performance: 133 }
      ]
    end
  end if Rails.version >= '4.1'

  def test_performance_glance_year_chart_data
    with_locale 'en' do
      with_people_settings 'workday_length' => 8 do
        check_performance_chart_data '2016-10-15', @person, PersonPerformanceCollector::YEAR, '2016-01-01', []
        check_performance_chart_data '2017-03-01', @person, PersonPerformanceCollector::YEAR, nil, []
      end

      with_people_settings 'workday_length' => 8 do
        check_performance_chart_data '2017-03-31', @person, PersonPerformanceCollector::YEAR, nil, [
          { date: '2017-03-27'.to_date, value: 1, tooltip: '6.0h | 75%' },
          { date: '2017-03-28'.to_date, value: 1, tooltip: '6.75h | 84%' },
          { date: '2017-03-29'.to_date, value: 1, tooltip: '7.0h | 88%' },
          { date: '2017-03-30'.to_date, value: 2, tooltip: '7.25h | 91%' },
          { date: '2017-03-31'.to_date, value: 3, tooltip: '9.5h | 119%' }
        ]
      end

      with_people_settings 'workday_length' => 6 do
        check_performance_chart_data '2017-03-31', @person, PersonPerformanceCollector::YEAR, nil, [
          { date: '2017-03-27'.to_date, value: 2, tooltip: '6.0h | 100%' },
          { date: '2017-03-28'.to_date, value: 3, tooltip: '6.75h | 113%' },
          { date: '2017-03-29'.to_date, value: 3, tooltip: '7.0h | 117%' },
          { date: '2017-03-30'.to_date, value: 3, tooltip: '7.25h | 121%' },
          { date: '2017-03-31'.to_date, value: 3, tooltip: '9.5h | 158%' }
        ]
      end
    end
  end if Rails.version >= '4.1'

  private

  def metrics(total_hours, performance, overtime, weekends_hours)
    { total_hours: total_hours,
      performance: performance,
      overtime: overtime,
      weekends_hours: weekends_hours }
  end

  def with_app_settings(non_working_week_days, workday_length)
    with_settings non_working_week_days: non_working_week_days do
      with_people_settings 'workday_length' => workday_length do
        yield if block_given?
      end
    end
  end

  def check_performance_metrics(date, person, interval_type, start_date, expected_metrics)
    travel_to date do
      ppc = PersonPerformanceCollector.new(person, interval_type, start_date)
      assert_equal expected_metrics[:total_hours], ppc.total_hours, 'collector.total_hours does not match'
      assert_equal expected_metrics[:performance], ppc.performance, 'collector.performance does not match'
      assert_equal expected_metrics[:overtime], ppc.overtime, 'collector.overtime does not match'
      assert_equal expected_metrics[:weekends_hours], ppc.weekends_hours, 'collector.weekends_hours does not match'
    end
  end

  def check_performance_chart_data(date, person, interval_type, start_date, expected_data)
    travel_to date do
      ppc = PersonPerformanceCollector.new(person, interval_type, start_date)
      assert_equal expected_data, ppc.chart_data, 'collector.chart_data does not match'
    end
  end
end
