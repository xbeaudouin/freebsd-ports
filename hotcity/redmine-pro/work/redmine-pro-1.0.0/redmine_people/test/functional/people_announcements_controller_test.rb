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

class PeopleAnnouncementsControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users, :projects, :roles, :members, :member_roles, :trackers, :projects_trackers, :issue_statuses
  fixtures :people_announcements, :people_information
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_announcements, :people_information])

  def setup
    @request.session[:user_id] = 2
    Setting.plugin_redmine_people['visibility'] = 1
    PeopleAcl.create(2, ['view_people', 'edit_announcement'])
  end

  def test_new
    with_people_settings 'use_announcements' => '1' do
      compatible_request :get, :new
      assert_response :success
      assert_select 'textarea.wiki-edit'
    end
  end

  def test_create
    with_people_settings 'use_announcements' => '1' do
      assert_difference 'PeopleAnnouncement.count' do
        compatible_request :post, :create, :people_announcement => { :description => 'desc',
                                                                     :frequency => 'once',
                                                                     :start_date => Date.today,
                                                                     :end_date => Date.today + 1.year,
                                                                     :active => true,
                                                                     :kind => 'notice' }
      end
    end
  end

  def test_update
    with_people_settings 'use_announcements' => '1' do
      announcement = people_announcements(:people_announcement_001)
      compatible_request :post, :update, :id => announcement.id, :people_announcement => 'New desc'
      announcement.reload
      assert 'New desc', announcement.description
    end
  end

  def test_put_update_with_attachment
    with_people_settings 'use_announcements' => '1' do
      set_tmp_attachments_directory
      announcement = people_announcements(:people_announcement_001)
      assert_no_difference 'PeopleAnnouncement.count' do
        assert_difference 'Attachment.count' do
          compatible_request :put, :update, :id => announcement.id,
                                            :people_announcement => { :description => 'This is the description' },
                                            :attachments => { '1' => { 'file' => uploaded_test_file('testfile.txt', 'text/plain') } }
        end
      end
      attachment = Attachment.order('id DESC').first
      assert_equal PeopleAnnouncement.find(announcement.id), attachment.container
    end
  end

  def test_get_edit
    with_people_settings 'use_announcements' => '1' do
      announcement = people_announcements(:people_announcement_001)
      compatible_request :get, :edit, :id => announcement.id
      assert_response 200
    end
  end

  def test_destory
    with_people_settings 'use_announcements' => '1' do
      assert_difference 'PeopleAnnouncement.count', -1 do
        compatible_request :post, :destroy, :id => people_announcements(:people_announcement_001).id
      end
    end
  end

  def test_new_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_announcements' => '1' do
      compatible_request :get, :new
      assert_response 403
    end
  end

  def test_index_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_announcements' => '1', 'visibility' => '0' do
      compatible_request :get, :index
      assert_response 403
    end
  end

  def test_create_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_announcements' => '1' do
      compatible_request :post, :create
      assert_response 403
    end
  end

  def test_update_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_announcements' => '1' do
      compatible_request :post, :update, :id => people_announcements(:people_announcement_001).id
      assert_response 403
    end
  end

  def test_destory_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_announcements' => '1' do
      assert_difference 'PeopleAnnouncement.count', 0 do
        compatible_request :post, :destroy, :id => people_announcements(:people_announcement_001).id
      end
    end
  end

  def test_preview
    with_people_settings 'use_announcements' => '1' do
      compatible_request :post, :preview, :people_announcement => { :description => 'desc',
                                                                    :frequency => 'once',
                                                                    :start_date => Date.today,
                                                                    :end_date => Date.today + 1.year,
                                                                    :active => true,
                                                                    :kind => 'notice' }
      assert_response :success
      assert_select '.wiki', :text => 'desc'
    end
  end

  def test_active
    with_people_settings 'use_announcements' => '1' do
      today_announcements = PeopleAnnouncement.today.count
      compatible_request :get, :index
      assert_response :success
      assert_select '.wiki', :count => today_announcements #show all active announcement for today
      assert_equal Date.today.to_s, cookies[:announcements_date]
    end
  end

  def test_active_when_no_active_nofitications
    with_people_settings 'use_announcements' => '1' do
      PeopleAnnouncement.where(:active => true).update_all(:active => false)
      compatible_request :get, :index
      assert announcements_in_list.empty?
    end
  end

  def test_active_when_off_setting
    with_people_settings 'use_announcements' => '0' do
      compatible_request :get, :index
      assert_response :redirect
    end
  end

  def test_second_call_active
    with_people_settings 'use_announcements' => '1' do
      compatible_request :get, :index
      compatible_request :get, :index
      assert_equal announcements_in_list.size, 0
    end
  end

  def test_change_saved_announcement
    with_people_settings 'use_announcements' => '1' do
      compatible_request :get, :index
      announcement = people_announcements(:people_announcement_001)
      announcement.description = 'changed description'
      announcement.save
      compatible_request :get, :index
      assert_select '.wiki', :text => 'changed description'
    end
  end

  def test_add_new_today_people_announcement_after_first_show
    with_people_settings 'use_announcements' => '1' do
      compatible_request :get, :index
      announcement = PeopleAnnouncement.create(:description => 'new announcement',
                                               :end_date => Date.today,
                                               :kind => 'error',
                                               :frequency => 'once',
                                               :active => true)
      compatible_request :get, :index
      assert_select '.wiki', :text => announcement.description
    end
  end

  def test_people_announcement_with_future_date
    with_people_settings 'use_announcements' => '1' do
      compatible_request :get, :index
      announcement = PeopleAnnouncement.create(:description => 'new announcement',
                                               :end_date => Date.today,
                                               :kind => 'error',
                                               :frequency => 'once',
                                               :active => true,
                                               :start_date => Date.today + 1.day)
      compatible_request :get, :index
      assert !announcements_in_list.include?(announcement)
    end
  end

  def test_show_birthdays_with_ages
    person = Person.find(1)
    person.information.birthday = (Date.today + (is_29_february?(Date.today) ? 1 : 0)) - 33.years
    person.save
    with_people_settings 'use_announcements' => '1', 'visibility' => '1', 'hide_age' => '0', 'show_birthday_announcements' => '1' do
      compatible_request :get, :index
      assert_select '#announcement-show .birthdays'
      # expect how old person will be in this year, not current age!
      assert_select '#announcement-show .contacts_header', "#{person.name} (#{person.age + 1})"
    end
  end

  def test_didnt_show_tomorrow_birthday_when_have_not_today
    person = Person.find(1)
    person.information.birthday = (Date.today + (is_29_february?(Date.today) ? 1 : 0) + 1) - 33.years
    person.save
    with_people_settings 'use_announcements' => '1', 'visibility' => '1', 'hide_age' => '0', 'show_birthday_announcements' => '1' do
      compatible_request :get, :index
      assert_select '#announcement-show .birthdays', :count => 0
      assert_select '#announcement-show .contacts_header', :count => 0
    end
  end

  def test_show_birthdays_without_ages
    person = Person.find(1)
    person.information.birthday = (Date.today + (is_29_february?(Date.today) ? 1 : 0)) - 33.years
    person.save
    with_people_settings 'use_announcements' => '1', 'visibility' => '1', 'hide_age' => '1', 'show_birthday_announcements' => '1' do
      compatible_request :get, :index
      assert_select '#announcement-show .birthdays'
      assert_select '#announcement-show .contacts_header', "#{person.name}"
    end
  end

  def test_show_birthdays_no_permission
    person = Person.find(1)
    person.information.birthday = Date.today - 33.years
    person.save
    @request.session[:user_id] = 3
    with_people_settings 'use_announcements' => '1' do
      compatible_request :get, :index
      assert_select '#announcement-show .birthdays', :count => 0
    end
  end

  private

  def is_29_february?(date)
    date.day == 29 && date.month == 2
  end
end
