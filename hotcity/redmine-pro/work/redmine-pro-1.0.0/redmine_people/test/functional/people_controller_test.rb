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

class PeopleControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper
  fixtures :users
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  # Fixtures with the same names overwriting each other. For example, time_entries will be restored only from the People plugin.
  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                                          [:people_holidays, :people_work_experiences, :departments, :people_information,
                                           :custom_fields, :custom_values, :attachments, :time_entries])

  def setup
    @person = Person.find(4)
    @person_params = { :login => 'login',
                       :password => '12345678',
                       :password_confirmation => '12345678',
                       :firstname => 'Ivan',
                       :lastname => 'Ivanov',
                       :mail => 'ivan@ivanov.com',
                       :information_attributes => {
                         :facebook => 'Facebook',
                         :middlename => 'Ivanovich' },
                       :tag_list => 'Tag1, Tag2'
                     }
    # Remove accesses operations
    Setting.plugin_redmine_people = {}
    set_fixtures_attachments_directory
  end

  def teardown
    set_tmp_attachments_directory
  end

  def access_message(action)
    "No access for the #{action} action"
  end

  def test_without_authorization
    # Get
    [:index, :show, :new, :edit].each do |action|
      compatible_request :get, action, :id => @person.id
      assert_response 302, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, :id => @person.id
      assert_response 302, access_message(action)
    end

    compatible_request :delete, :destroy_avatar, :id => @person.id
    assert_response 302
  end

  def test_with_deny_user
    @request.session[:user_id] = 2
    # Get
    [:show, :index, :new, :edit].each do |action|
      compatible_request :get, action, :id => @person.id
      assert_response 403, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      compatible_request :post, action, :id => @person.id
      assert_response 403, access_message(action)
    end

    compatible_request :delete, :destroy_avatar, :id => @person.id
    assert_response 403
  end

  def test_get_index
    @request.session[:user_id] = 1
    compatible_request :get, :index
    assert_response :success
    assert_select 'h1 a', 'Redmine Admin'
  end

  def test_get_index_without_departments
    @request.session[:user_id] = 1
    Department.delete_all
    compatible_request :get, :index, :set_filter => '1'
    assert_response :success
  end
  def test_get_index_with_all_fields
    @request.session[:user_id] = 1

    person = Person.find(1)
    person.tag_list = 'Tag1'
    person.save

    compatible_request :get, :index, :set_filter => '1', :c => PeopleQuery.available_columns.map(&:name), :people_list_style => 'list'
    assert_response :success
    assert_select 'tr#person-1 td.id a[href=?]', '/people/1'
    assert_select 'tr#person-1 td.tags', 'Tag1'
  end

  def test_get_index_with_filters
    @request.session[:user_id] = 1
    compatible_request :get, :index, :group_by => 'department',
        :f => ['firstname',
               'lastname',
               'middlename',
               'gender',
               'mail',
               'address',
               'phone',
               'skype',
               'twitter',
               'birthday',
               'job_title',
               'company',
               'appearance_date',
               'department status'],

        :op => { 'firstname' => '=',
                 'lastname' => '=',
                 'middlename' => '=',
                 'gender' => '=',
                 'mail' => '=',
                 'address' => '=',
                 'phone' => '=',
                 'skype' => '=',
                 'twitter' => '=',
                 'birthday' => '=',
                 'job_title' => '=',
                 'company' => '=',
                 'appearance_date' => '=',
                 'department' => '=',
                 'status' => '='
              },
        :v => { 'firstname' => ['Redmine'],
                'lastname' => ['Admin'],
                'middlename' => ['Petrovich'],
                'gender' => ['0'],
                'mail' => ['admin@somenet.foo'],
                'address' => ['Korolevo street'],
                'phone' => ['89125555555'],
                'skype' => ['Flex'],
                'twitter' => ['sky'],
                'birthday' => ['1991-07-19'],
                'job_title' => ['disigner'],
                'company' => ['IBM'],
                'appearance_date' => ['2014-07-20'],
                'department' => ['2'],
                'status' => ['1']
              }
    assert_response :success
    assert_select 'h1 a', 'Redmine Admin'
  end

  def test_get_index_with_tag
    @request.session[:user_id] = 1

    person = Person.find(4)
    person.tag_list = 'Tag1, Tag2'
    person.save

    compatible_request :get, :index, :f => ['people_tags'], :op => { 'people_tags' => "=" }, :v => { 'people_tags' => ['Tag1'] }

    assert_select 'h1 a', :count => 0, :text => /Redmine Admin/
    assert_select 'h1 a', 'Robert Hill'
  end

  def test_get_index_as_table
    @request.session[:user_id] = 1

    compatible_request :get, :index, :people_list_style => 'list',
                                     :f => ['cf_1'],
                                     :set_filter => '1',
                                     :op => { 'cf_1' => '=' },
                                     :v => { 'cf_1' => ['Sitroen'] },
                                     :c => ['firstname', 'cf_1', 'cf_2'] # Show custom field columns
    assert_no_match %r{Volvo}, @response.body
    assert_match %r{Sitroen}, @response.body
  end

  def test_get_show
    @request.session[:user_id] = 1
    compatible_request :get, :show, :id => @person.id
    assert_response :success
    assert_select 'h1', /Robert Hill/
  end
  def test_get_vcf
    @request.session[:user_id] = 1
    phone_old_value = @person.information.phone
    @person.information.update_attribute(:phone, ', +7(123)- 45-67, 8(111)22-33-44, 1-234-456')
    compatible_request :get, :show, :id => @person.id, :format => 'vcf'
    assert_response :success
    assert_match 'N:Hill;Robert;Vahtangovich;;', @response.body
    assert_match 'TEL:+7(123)-45-67', @response.body
    assert_match 'TEL:8(111)22-33-44', @response.body
    assert_match 'TEL:1-234-456', @response.body
  ensure
    @person.information.update_attribute(:phone, phone_old_value)
  end

  def test_get_new
    @request.session[:user_id] = 1
    compatible_request :get, :new
    assert_response :success
  end

  def test_get_edit
    @request.session[:user_id] = 1
    compatible_request :get, :edit, :id => @person.id
    assert_response :success
    assert_select "input[value='Hill']"
  end

  def test_post_create
    @request.session[:user_id] = 1
    compatible_request :post, :create, :person => @person_params
    person = Person.last
    assert_redirected_to :action => 'show', :id => person.id
    assert_equal ['ivan@ivanov.com', 'Ivanovich'], [person.email, person.middlename]
    assert_equal ['Tag1', 'Tag2'], person.tag_list.sort
  end

  def test_put_update
    @request.session[:user_id] = 1
    compatible_request :post, :update, :id => @person.id,
                                       :person => {
                                         :firstname => 'firstname',
                                         :information_attributes => { :facebook => 'Facebook2' }
                                       }
    @person.reload
    assert_redirected_to :action => 'show', :id => @person.id
    assert_equal ['firstname', 'Facebook2'], [@person.firstname, @person.facebook]
  end

  def test_update_with_attachment
    @request.session[:user_id] = 1
    compatible_request :post, :update, :id => '8', :tab => 'files',
                                       :attachments => { '1' => { 'file' => uploaded_test_file('testfile.txt', 'text/plain'),
                                                                  'description' => 'test file' } }

    assert_response 302
    assert_redirected_to tabs_person_path(8, :tab => 'files')

    attachment = Attachment.order('id DESC').first

    assert_equal User.find(8), attachment.container
    assert_equal 1, attachment.author_id
    assert_equal 'testfile.txt', attachment.filename
    assert_equal 'text/plain', attachment.content_type
    assert_equal 'test file', attachment.description

    assert File.exists?(attachment.diskfile)
  end

  def test_destroy
    @request.session[:user_id] = 1
    compatible_request :post, :destroy, :id => 4
    assert_redirected_to :action => 'index'
    assert_raises(ActiveRecord::RecordNotFound) do
      Person.find(4)
    end
  end

  def test_destroy_avatar
    @request.session[:user_id] = 1
    avatar = people_uploaded_file('testfile_1.png', 'image/png')

    a = Attachment.new(:container => @person,
                       :file =>  avatar, :description => 'avatar',
                       :author => User.find(1))
    assert a.save
    assert @person.avatar.present?

    compatible_request :delete, :destroy_avatar, :id => 4
    assert_redirected_to :action => 'edit', :id => 4
    assert @person.reload.avatar.blank?
  end

  def test_should_bulk_edit_people
    @request.session[:user_id] = 1
    compatible_request :post, :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_not_nil people_in_list
  end

  def test_should_not_bulk_edit_people_by_deny_user
    @request.session[:user_id] = 4
    compatible_request :get, :bulk_edit, :ids => [1, 2]
    assert_response 403
  end

  def test_should_put_bulk_update
    @request.session[:user_id] = 1

    compatible_request :post, :bulk_update, :ids => [2, 4], :person => { :status => 1,
                                                                         :information_attributes => {
                                                                           :manager_id => 1,
                                                                           :gender => 1,
                                                                           :appearance_date => '2017-01-01',
                                                                           :job_title => 'Bulk job title' }
                                                                       },
                                                            :add_tag_list => 'bulk, edit, tags, main',
                                                            :delete_tag_list => 'main'

    assert_redirected_to :controller => 'people', :action => 'index'
    people = Person.find([2, 4])
    people.each do |person|
      assert_equal 'Bulk job title', person.information.job_title
      assert_equal 1, person.status
      assert_equal 1, person.information.manager_id
      assert_equal 1, person.gender
      assert_equal '2017-01-01', person.appearance_date.strftime('%Y-%m-%d')
      tag_list = person.tag_list # Need for 4 rails
      assert tag_list.include?('bulk')
      assert tag_list.include?('edit')
      assert tag_list.include?('tags')
      assert !tag_list.include?('main')
    end
  end

  def test_should_not_put_bulk_update_by_deny_user
    @request.session[:user_id] = 4

    compatible_request :post, :bulk_update, :ids => [1, 2], :person => {
      :status => 1,
      :information_attributes => {
        :manager_id => 1,
        :gender => 1,
        :appearance_date => '2017-01-01',
        :job_title => 'Bulk job title'
      },
      :tag_list => 'bulk, edit, tags' }
    assert_response 403
  end

  def test_load_tab
    @request.session[:user_id] = @person.id
    compatible_xhr_request :get, :load_tab, :tab_name => 'activity', :partial => 'activity', :id => @person.id
    assert_response :success

    compatible_xhr_request :get, :load_tab, :tab_name => 'files', :partial => 'attachments', :id => @person.id
    assert_response :success

    compatible_xhr_request :get, :load_tab, :tab_name => 'projects', :partial => 'projects', :id => @person.id
    assert_response :success
    compatible_xhr_request :get, :load_tab, :tab_name => 'subordinates', :partial => 'subordinates', :id => @person.id
    assert_response :success
    compatible_xhr_request :get, :load_tab, :tab_name => 'work_experience', :partial => 'people_work_experiences/list', :id => @person.id
    assert_response :success
  end
  def test_remove_subordinate_without_deny
    @request.session[:user_id] = 2

    compatible_xhr_request :post, :remove_subordinate, :id => @person.id, :subordinate_ids => ['1', '2']
    assert_response 403
  end

  def test_remove_subordinate
    @request.session[:user_id] = 1

    compatible_xhr_request :post, :remove_subordinate, :id => 3, :subordinate_id => '4'
    assert_response :success
    assert !@person.subordinates.any?
  end

  def test_get_new_without_default_group
    with_people_settings 'default_group' => '' do
      @request.session[:user_id] = 1
      compatible_request :get, :new
      assert_response :success
      assert_select "input[type=hidden][name='person[group_ids][]']", false, 'No groups'
    end
  end

  def test_get_new_with_default_group
    with_people_settings 'default_group' => '456' do
      @request.session[:user_id] = 1
      compatible_request :get, :new
      assert_response :success
      assert_select "input[type=hidden][name='person[group_ids][]'][value='456']"
    end
  end

  def test_post_create_with_default_group
    @request.session[:user_id] = 1
    @person_params[:group_ids] = [10]
    compatible_request :post, :create, :person => @person_params
    person = Person.last
    assert_equal 10, person.groups.first.id
  end

  def test_post_create_with_deleted_default_group
    @request.session[:user_id] = 1
    @person_params[:group_ids] = [777]
    compatible_request :post, :create, :person => @person_params
    person = Person.last
    assert_nil person.groups.first
  end

  def test_sidebar_next_holidays
    @request.session[:user_id] = 1
    compatible_request :get, :index
    assert_response :success
    assert_select '#next_holidays', :count => 0

    holiday = PeopleHoliday.new(:start_date => Date.today + 5.day, :name => 'New holiday')
    holiday.save
    compatible_request :get, :index
    assert_response :success
    assert_select '#next_holidays', :count => 1
  end
  def test_get_index_custom_fields
    PeopleAcl.create(@person.id, ['view_people'])
    @request.session[:user_id] = @person.id

    compatible_request :get, :index, :people_list_style => 'list', :set_filter => '1'
    assert_select 'select#add_filter_select' do
      assert_select 'option', :count => 1, :text => 'Test field 7'
      assert_select 'option', :count => 1, :text => 'Test field 8'
      assert_select 'option', :count => 0, :text => 'Test field 9'
      assert_select 'option', :count => 0, :text => 'Test field 10'
    end

    tag_id = Redmine::VERSION.to_s < '3.4' ? 'columns' : 'c'
    assert_select "select#available_#{tag_id}" do
      assert_select 'option', :count => 1, :text => 'Test field 7'
      assert_select 'option', :count => 1, :text => 'Test field 8'
      assert_select 'option', :count => 0, :text => 'Test field 9'
      assert_select 'option', :count => 0, :text => 'Test field 10'
    end
  end

  def test_get_show_custom_fields
    @request.session[:user_id] = @person.id

    compatible_request :get, :show, :id => @person.id
    assert_match %r{Test field 7}, @response.body
    assert_match %r{Test field 8}, @response.body
    assert_no_match %r{Test field 9}, @response.body
    assert_no_match %r{Test field 10}, @response.body
  end

  def test_get_new_custom_fields
    PeopleAcl.create(@person.id, ['add_people'])
    @request.session[:user_id] = @person.id

    compatible_request :get, :new
    assert_match %r{Test field 7}, @response.body
    assert_no_match %r{Test field 8}, @response.body
    assert_match %r{Test field 9}, @response.body
    assert_no_match %r{Test field 10}, @response.body
  end

  def test_get_edit_custom_fields
    PeopleAcl.create(@person.id, ['edit_people'])
    @request.session[:user_id] = @person.id

    compatible_request :get, :edit, :id => @person.id
    assert_match %r{Test field 7}, @response.body
    assert_no_match %r{Test field 8}, @response.body
    assert_match %r{Test field 9}, @response.body
    assert_no_match %r{Test field 10}, @response.body
  end

  def test_get_index_custom_fields_by_admin
    @request.session[:user_id] = 1

    compatible_request :get, :index, :people_list_style => 'list', :set_filter => '1'
    assert_select 'select#add_filter_select' do
      assert_select 'option', :count => 1, :text => 'Test field 7'
      assert_select 'option', :count => 1, :text => 'Test field 8'
      assert_select 'option', :count => 1, :text => 'Test field 9'
      assert_select 'option', :count => 1, :text => 'Test field 10'
    end

    tag_id = Redmine::VERSION.to_s < '3.4' ? 'columns' : 'c'
    assert_select "select#available_#{tag_id}" do
      assert_select 'option', :count => 1, :text => 'Test field 7'
      assert_select 'option', :count => 1, :text => 'Test field 8'
      assert_select 'option', :count => 1, :text => 'Test field 9'
      assert_select 'option', :count => 1, :text => 'Test field 10'
    end
  end

  def test_get_show_custom_fields_by_admin
    @request.session[:user_id] = 1

    compatible_request :get, :show, :id => @person.id
    assert_match %r{Test field 7}, @response.body
    assert_match %r{Test field 8}, @response.body
    assert_match %r{Test field 9}, @response.body
    assert_match %r{Test field 10}, @response.body
  end

  def test_get_new_custom_fields_by_admin
    @request.session[:user_id] = 1

    compatible_request :get, :new
    assert_match %r{Test field 7}, @response.body
    assert_match %r{Test field 8}, @response.body
    assert_match %r{Test field 9}, @response.body
    assert_match %r{Test field 10}, @response.body
  end

  def test_get_edit_custom_fields_by_admin
    @request.session[:user_id] = 1

    compatible_request :get, :edit, :id => @person.id
    assert_match %r{Test field 7}, @response.body
    assert_match %r{Test field 8}, @response.body
    assert_match %r{Test field 9}, @response.body
    assert_match %r{Test field 10}, @response.body
  end

  def test_without_permission_view_performance
    PeopleAcl.create(@person.id, %w(view_people))
    tab_should_not_be_available(@person.id, 1, 'performance')
    tab_should_be_available(@person.id, @person.id, 'performance') # Own performance tab always available
    tab_should_be_available(1, @person.id, 'performance') # Performance tab available for admin
  end

  def test_with_permission_view_performance
    PeopleAcl.create(@person.id, %w(view_people view_performance))
    tab_should_be_available(@person.id, 1, 'performance')
    tab_should_be_available(@person.id, @person.id, 'performance')
  end

  def test_post_create_with_workday_length
    @request.session[:user_id] = 1

    [
      { login: 'ivan1', email: 'ivan1@mail.com', value: '', workday_length: nil },
      { login: 'ivan2', email: 'ivan2@mail.com', value: 0, workday_length: 0 },
      { login: 'ivan3', email: 'ivan3@mail.com', value: 8, workday_length: 8 },
      { login: 'ivan4', email: 'ivan4@mail.com', value: 24, workday_length: 24 }
    ].each do |data|
      @person_params[:information_attributes][:workday_length] = data[:value]
      @person_params[:login] = data[:login]
      @person_params[:mail] = data[:email]

      compatible_request :post, :create, person: @person_params
      person = Person.last
      assert_redirected_to action: 'show', id: person.id
      assert_equal data[:email], person.email
      assert_equal data[:workday_length], person.information.workday_length
    end
  end

  def test_put_update_with_workday_length
    @request.session[:user_id] = 1

    [
      { value: '', workday_length: nil },
      { value: 0, workday_length: 0 },
      { value: 8, workday_length: 8 },
      { value: 24, workday_length: 24 },
    ].each do |data|
      @person_params[:information_attributes][:workday_length] = data[:value]
      compatible_request :put, :update, id: @person.id, person: @person_params
      @person.reload
      assert_redirected_to action: 'show', id: @person.id
      assert_equal data[:workday_length], @person.information.workday_length
    end

    [-1, 25].each do |val|
      @person_params[:information_attributes][:workday_length] = val
      compatible_request :put, :update, id: @person.id, person: @person_params
      @person.reload
      assert_response 400
    end
  end

  def test_performance_tab_for_person_without_information
    person = Person.find(5)
    assert_equal nil, person.information
    tab_should_be_available(1, person.id, 'performance')
  end

  def test_performance_tab_for_person_without_time_entries
    @request.session[:user_id] = 1
    person = Person.find(2)
    assert person.time_entries.blank?

    compatible_request :get, :show, id: person.id
    assert_response :success
    assert_select '#tab-performance', 0
    assert_select '#tab-placeholder-performance', 0
  end

  def test_should_get_performance_histogram_chart
    @request.session[:user_id] = 1
    with_people_settings 'workday_length' => 8 do
      travel_to Date.new(2017,4, 5) do
        compatible_xhr_request :get, :load_tab, id: @person.id, tab_name: 'performance', partial: 'performance'
        assert_response :success
        assert_match /performance-histogram/, response.body
        assert_no_match /performance-glanceyear-chart/, response.body
      end
    end
  end if Rails.version >= '4.1' # travel_to helper added in Rails  4.1 (Redmine version >= 3.0)

  def test_should_get_performance_glance_year_chart
    @request.session[:user_id] = 1
    with_people_settings 'workday_length' => 8 do
      travel_to Date.new(2017,4, 5) do
        compatible_xhr_request :get, :load_tab, {
          id: @person.id,
          tab_name: 'performance',
          partial: 'performance',
          interval_type: PersonPerformanceCollector::YEAR
        }

        assert_response :success
        assert_match /performance-glanceyear-chart/, response.body
        assert_no_match /performance-histogram/, response.body
      end
    end
  end if Rails.version >= '4.1'

  def test_get_index_with_search
    @request.session[:user_id] = 1
    with_settings :user_format => 'lastnamefirstname' do
      compatible_request :get, :index, set_filter: '1', f: [''], search: 'smithjoh'
      assert_response :success
      assert_select 'table.people td.name h1 a', 1
    end
  end

  private

  def tab_should_be_available(user_id, person_id, tab_name)
    @request.session[:user_id] = user_id

    compatible_request :get, :show, id: person_id
    assert_response :success
    assert_select "#tab-#{tab_name}", 1
    assert_select "#tab-placeholder-#{tab_name}", 1

    compatible_request :get, :show, id: person_id, tab: tab_name
    assert_response :success
    assert_select "#tab-#{tab_name}", 1
    assert_select "#tab-placeholder-#{tab_name}", 1

    compatible_xhr_request :get, :load_tab, id: person_id, tab_name: tab_name, partial: tab_name
    assert_response :success
  end

  def tab_should_not_be_available(user_id, person_id, tab_name)
    @request.session[:user_id] = user_id

    compatible_request :get, :show, id: person_id
    assert_response :success
    assert_select "#tab-#{tab_name}", 0
    assert_select "#tab-placeholder-#{tab_name}", 0

    compatible_request :get, :show, id: person_id, tab: tab_name
    assert_response :forbidden

    compatible_xhr_request :get, :load_tab, id: person_id, tab_name: tab_name, partial: tab_name
    assert_response :forbidden
  end
end
