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

class PeopleWorkExperiencesControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper
  fixtures :users
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_work_experiences, :departments, :people_information, :custom_fields, :custom_values, :attachments])

  def setup
    @person = Person.find(1)
    @work_experience = PeopleWorkExperience.find(1)
    @work_experience_url_params = { :person_id => @person.id, :id => @work_experience.id }
    @work_experience_params = { :previous_company_name => 'New Previous Company',
                                :job_title => 'New Job Title',
                                :from_date => '2016-01-01',
                                :to_date => '2016-03-01',
                                :description => 'New Description' }
    # Remove accesses operations
    Setting.plugin_redmine_people = {}
    set_fixtures_attachments_directory
  end

  def access_message(action)
    "No access for the #{action} action"
  end

  def test_without_authorization
    # Get
    [:new, :edit].each do |action|
      compatible_request :get, action, @work_experience_url_params
      assert_response 302, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, @work_experience_url_params
      assert_response 302, access_message(action)
    end
  end

  def test_with_deny_user
    @request.session[:user_id] = 2
    # Get
    [:new, :edit].each do |action|
      compatible_request :get, action, @work_experience_url_params
      assert_response 403, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, @work_experience_url_params
      assert_response 403, access_message(action)
    end
  end

  def test_with_access_rights
    PeopleAcl.create(2, ['view_people', 'edit_work_experience'])
    @request.session[:user_id] = 2

    # Get
    [:new, :edit].each do |action|
      compatible_request :get, action, @work_experience_url_params
      assert_response :success, access_message(action)
    end

    [:new, :edit].each do |action|
      compatible_request :get, action, @work_experience_url_params
      assert_response :success, access_message(action)
    end

    # Post
    compatible_request :post, :create, @work_experience_url_params
    assert_response :success

    [:update, :destroy].each do |action|
      compatible_request :post, action, @work_experience_url_params
      assert_response 302
    end
  end

  def test_with_own_access_rights
    PeopleAcl.create(2, ['view_people', 'edit_own_work_experience'])
    @request.session[:user_id] = 2
    work_experience = PeopleWorkExperience.find(2)
    work_experience_url_params = { :person_id => 2, :id => work_experience.id }

    # Get
    [:new, :edit].each do |action|
      compatible_request :get, action, work_experience_url_params
      assert_response :success, access_message(action)
    end

    [:new, :edit].each do |action|
      compatible_request :get, action, work_experience_url_params
      assert_response :success, access_message(action)
    end

    # Post
    compatible_request :post, :create, work_experience_url_params
    assert_response :success

    [:update, :destroy].each do |action|
      compatible_request :post, action, work_experience_url_params
      assert_response 302
    end
  end

  def test_create
    @request.session[:user_id] = 1
    compatible_request :post, :create, :person_id => @request.session[:user_id],
                                       :work_experience => @work_experience_params
    work_experience = PeopleWorkExperience.last
    assert_response 302
    assert_redirected_to :controller => 'people', :action => 'show', :id => @request.session[:user_id], :tab => 'work_experience'
    assert_equal ['New Previous Company'], [work_experience.previous_company_name]
  end

  def test_update
    @request.session[:user_id] = 1
    compatible_request :post, :update, :person_id => @request.session[:user_id], :id => '1',
                                       :work_experience => { :previous_company_name => 'New one previous company name' }
    work_experience = PeopleWorkExperience.find(1)
    assert_response 302
    assert_redirected_to :controller => 'people', :action => 'show', :id => @request.session[:user_id], :tab => 'work_experience'
    assert_equal ['New one previous company name'], [work_experience.previous_company_name]
  end
end
