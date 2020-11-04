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

class DayoffQueryTest < ActiveSupport::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users
  fixtures :email_addresses if Redmine::VERSION.to_s >= '3.0'
  RedminePeople::TestCase.create_fixtures(
    Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
    [:people_holidays, :departments, :people_information, :leave_types, :dayoffs]
  )

  def setup
    @query = DayoffQuery.new(name: '_')
    @admin = User.find(1)
    @person_3 = Person.find(3)
    User.current = @admin
  end

  def test_dayoffs_without_filters
    assert_equal (1..9).to_a, @query.dayoffs.map(&:id).sort
    assert_equal 3, @query.dayoffs(offset: 2, limit: 3).size
  end

  def test_user_filter
    @query = @query.build_from_params(f: ['user_id'], op: { 'user_id' => '=' }, v: { 'user_id' => ['2'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['user_id'], op: { 'user_id' => '!' }, v: { 'user_id' => ['2', '3'] })
    assert_equal [7, 8, 9], @query.dayoffs.map(&:id).sort
  end

  def test_leave_type_filter
    @query = @query.build_from_params(f: ['leave_type_id'], op: { 'leave_type_id' => '=' }, v: { 'leave_type_id' => ['1'] })
    assert_equal [1, 4, 7], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['leave_type_id'], op: { 'leave_type_id' => '!' }, v: { 'leave_type_id' => ['2', '3'] })
    assert_equal [1, 4, 7], @query.dayoffs.map(&:id).sort
  end

  def test_start_date_filter
    @query = @query.build_from_params(f: ['start_date'], op: { 'start_date' => '>=' }, v: { 'start_date' => ['2019-05-01'] })
    assert_equal [1, 4, 7], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['start_date'], op: { 'start_date' => '><' }, v: { 'start_date' => ['2019-05-01', '2019-05-31'] })
    assert @query.dayoffs.blank?
  end

  def test_end_date_filter
    @query = @query.build_from_params(f: ['end_date'], op: { 'end_date' => '>=' }, v: { 'end_date' => ['2019-05-01'] })
    assert_equal [1, 4, 7], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['end_date'], op: { 'end_date' => '><' }, v: { 'end_date' => ['2019-05-01', '2019-05-01'] })
    assert_equal [], @query.dayoffs.map(&:id).sort
  end

  def test_firstname_filter
    @query = @query.build_from_params(f: ['firstname'], op: { 'firstname' => '~' }, v: { 'firstname' => ['john'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['firstname'], op: { 'firstname' => '=' }, v: { 'firstname' => [@person_3.firstname] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_lastname_filter
    @query = @query.build_from_params(f: ['lastname'], op: { 'lastname' => '~' }, v: { 'lastname' => ['smi'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['lastname'], op: { 'lastname' => '=' }, v: { 'lastname' => [@person_3.lastname] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_middlename_filter
    @query = @query.build_from_params(f: ['middlename'], op: { 'middlename' => '~' }, v: { 'middlename' => ['ibn'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['middlename'], op: { 'middlename' => '=' }, v: { 'middlename' => [@person_3.middlename] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_gender_filter
    @query = @query.build_from_params(f: ['gender'], op: { 'gender' => '=' }, v: { 'gender' => ['0'] })
    assert_equal (1..9).to_a, @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['gender'], op: { 'gender' => '=' }, v: { 'gender' => ['1'] })
    assert @query.dayoffs.blank?
  end

  def test_mail_filter
    @query = @query.build_from_params(f: ['mail'], op: { 'mail' => '~' }, v: { 'mail' => ['smi'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['mail'], op: { 'mail' => '=' }, v: { 'mail' => [@person_3.email] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_address_filter
    @query = @query.build_from_params(f: ['address'], op: { 'address' => '~' }, v: { 'address' => ['wall'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['address'], op: { 'address' => '=' }, v: { 'address' => [@person_3.address] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_phone_filter
    @query = @query.build_from_params(f: ['phone'], op: { 'phone' => '~' }, v: { 'phone' => ['222'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['phone'], op: { 'phone' => '=' }, v: { 'phone' => [@person_3.phone] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_skype_filter
    @query = @query.build_from_params(f: ['skype'], op: { 'skype' => '~' }, v: { 'skype' => ['arny'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['skype'], op: { 'skype' => '=' }, v: { 'skype' => [@person_3.skype] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_twitter_filter
    @query = @query.build_from_params(f: ['twitter'], op: { 'twitter' => '~' }, v: { 'twitter' => ['arny'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['twitter'], op: { 'twitter' => '=' }, v: { 'twitter' => [@person_3.twitter] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_facebook_filter
    @query = @query.build_from_params(f: ['facebook'], op: { 'facebook' => '~' }, v: { 'facebook' => ['arny'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['facebook'], op: { 'facebook' => '=' }, v: { 'facebook' => [@person_3.facebook] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_linkedin_filter
    @query = @query.build_from_params(f: ['linkedin'], op: { 'linkedin' => '~' }, v: { 'linkedin' => ['arny'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['linkedin'], op: { 'linkedin' => '=' }, v: { 'linkedin' => [@person_3.linkedin] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_job_title_filter
    @query = @query.build_from_params(f: ['job_title'], op: { 'job_title' => '~' }, v: { 'job_title' => ['archi'] })
    assert_equal [1, 2, 3], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['job_title'], op: { 'job_title' => '=' }, v: { 'job_title' => [@person_3.job_title] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort
  end

  def test_manager_filter
    @query = @query.build_from_params(f: ['manager_id'], op: { 'manager_id' => '=' }, v: { 'manager_id' => ['3'] })
    assert_equal [7, 8, 9], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['manager_id'], op: { 'manager_id' => '!' }, v: { 'manager_id' => ['3'] })
    assert_equal (1..6).to_a, @query.dayoffs.map(&:id).sort
  end

  def test_department_filter
    # With parent department
    @query = @query.build_from_params(f: ['department_id'], op: { 'department_id' => '=' }, v: { 'department_id' => ['1'] })
    assert_equal [7, 8, 9], @query.dayoffs.map(&:id).sort

    # With sub department
    @query = @query.build_from_params(f: ['department_id'], op: { 'department_id' => '=' }, v: { 'department_id' => ['3'] })
    assert_equal [7, 8, 9], @query.dayoffs.map(&:id).sort
  end

  def test_tags_filter
    @person_3.tag_list = 'Tag1'
    @person_3.save
    assert_equal @person_3.tags.first.to_s, 'Tag1'

    @query = @query.build_from_params(f: ['tags'], op: { 'tags' => '=' }, v: { 'tags' => ['Tag1'] })
    assert_equal [4, 5, 6], @query.dayoffs.map(&:id).sort

    @query = @query.build_from_params(f: ['tags'], op: { 'tags' => '!' }, v: { 'tags' => ['Tag1'] })
    assert_equal [1, 2, 3, 7, 8, 9], @query.dayoffs.map(&:id).sort
  end
end
