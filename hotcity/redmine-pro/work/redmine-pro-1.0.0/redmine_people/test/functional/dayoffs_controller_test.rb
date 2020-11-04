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

class DayoffsControllerTest < ActionController::TestCase
  include Redmine::I18n
  include RedminePeople::TestCase::TestHelper

  fixtures :users
  fixtures :email_addresses if Redmine::VERSION.to_s >= '3.0'
  RedminePeople::TestCase.create_fixtures(
    Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
    [:people_holidays, :departments, :people_information, :leave_types, :dayoffs]
  )

  def setup
    Setting.plugin_redmine_people = {}

    @admin = User.find(1)
    @user = User.find(2)

    @dayoff_params = {
      user_id: 2,
      leave_type_id: 2,
      start_date: '2019-04-01'.to_date,
      end_date: '2019-04-07'.to_date,
      hours_per_day: 4,
      notes: '4 hours work from home'
    }
  end

  # === Action :index ===

  def test_should_get_index_for_admin
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index
    assert_response :success
  end

  def test_should_get_index_with_permission_view_leave
    @request.session[:user_id] = @user.id
    PeopleAcl.create(@user.id, [:view_leave])
    compatible_request :get, :index
    assert_response :success
  end

  def test_should_not_access_index_without_permission_view_leave
    @request.session[:user_id] = @user.id
    compatible_request :get, :index
    assert_response :forbidden
  end

  def test_should_not_access_index_for_anonymous
    compatible_request :get, :index
    assert_response :redirect
  end

  def test_should_get_index_with_nodata
    return if Rails.version < '4.1' # travel_to helper added in Rails  4.1

    @request.session[:user_id] = @admin.id
    travel_to Date.new(2018, 12, 1) do
      compatible_request :get, :index
      assert_response :success
      assert_select 'p.nodata'
    end
  end

  def test_should_get_index_with_dayoffs_chart
    return if Rails.version < '4.1' # travel_to helper added in Rails  4.1

    @request.session[:user_id] = @admin.id
    travel_to Date.new(2019, 7, 1) do
      compatible_request :get, :index
      assert_response :success
      assert_select '.leave-planner-chart'
    end
  end

  def test_should_get_index_with_dayoffs_list
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE
    assert_response :success
    assert_select 'table.dayoffs.list' do
      assert_select 'tr.dayoff'
    end
  end

  def test_dayoffs_chart_with_grouping_by_manager
    should_get_dayoffs_chart_with_grouping_by :manager
  end

  def test_dayoffs_chart_with_grouping_by_department
    should_get_dayoffs_chart_with_grouping_by :department
  end

  def test_dayoffs_list_with_grouping_by_manager
    should_get_dayoffs_list_with_grouping_by :manager
  end

  def test_dayoffs_list_with_grouping_by_department
    should_get_dayoffs_list_with_grouping_by :department
  end

  def test_dayoffs_chart_with_user_filter
    return if Rails.version < '4.1' # travel_to helper added in Rails  4.1

    @request.session[:user_id] = @admin.id
    travel_to Date.new(2019, 7, 1) do
      compatible_request :get, :index, {
        set_filter: '1',
        f: ['user_id'],
        op: { 'user_id' => '=' },
        v: { 'user_id' => [2] }
      }
    end

    assert_response :success
    assert_select '.leave-planner-chart' do
      assert_select '.leave-planner-subjects > .user-subject', 1
    end
  end

  def test_dayoffs_list_with_user_filter
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, {
      list_style: DayoffQuery::TABLE_STYLE,
      set_filter: '1',
      f: ['user_id'],
      op: { 'user_id' => '=' },
      v: { 'user_id' => [2] }
    }

    assert_response :success
    assert_select 'table.dayoffs.list' do
      assert_select 'tr.dayoff', 3
    end
  end

  def test_index_sort_by_default
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE
    assert_response :success

    ids = dayoffs_in_list.map(&:id)
    assert_not_empty ids
    assert_equal ids.sort.reverse, ids
    assert_select 'table.dayoffs.sort-by-id.sort-desc'
  end

  def test_index_sort_by_id_asc
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, sort: 'id:asc'
    assert_response :success

    ids = dayoffs_in_list.map(&:id)
    assert_not_empty ids
    assert_equal ids.sort, ids
    assert_select 'table.dayoffs.sort-by-id.sort-asc'
  end

  def test_index_sort_by_user
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, sort: 'user:asc'
    assert_response :success

    users = dayoffs_in_list.map(&:user)
    assert_not_empty users
    assert_equal users.sort, users
    assert_select 'table.dayoffs.sort-by-user.sort-asc'
  end

  def test_index_sort_by_user_desc
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, sort: 'user:desc'
    assert_response :success

    users = dayoffs_in_list.map(&:user)
    assert_not_empty users
    assert_equal users.sort.reverse, users
    assert_select 'table.dayoffs.sort-by-user.sort-desc'
  end

  def test_index_sort_by_leave_type
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, sort: 'leave_type:asc'
    assert_response :success

    leave_type_names = dayoffs_in_list.map { |dayoff| dayoff.leave_type.name }
    assert_not_empty leave_type_names
    assert_equal leave_type_names.sort, leave_type_names
    assert_select 'table.dayoffs.sort-by-leave-type.sort-asc'
  end

  def test_index_sort_by_leave_type_desc
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, sort: 'leave_type:desc'
    assert_response :success

    leave_type_names = dayoffs_in_list.map { |dayoff| dayoff.leave_type.name }
    assert_not_empty leave_type_names
    assert_equal leave_type_names.sort.reverse, leave_type_names
    assert_select 'table.dayoffs.sort-by-leave-type.sort-desc'
  end

  def test_index_sort_by_start_date
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, sort: 'start_date:asc'
    assert_response :success

    start_dates = dayoffs_in_list.map(&:start_date)
    assert_not_empty start_dates
    assert_equal start_dates.sort, start_dates
    assert_select 'table.dayoffs.sort-by-start-date.sort-asc'
  end

  def test_index_sort_by_start_date_desc
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, sort: 'start_date:desc'
    assert_response :success

    start_dates = dayoffs_in_list.map(&:start_date)
    assert_not_empty start_dates
    assert_equal start_dates.sort.reverse, start_dates
    assert_select 'table.dayoffs.sort-by-start-date.sort-desc'
  end

  def test_index_sort_by_end_date
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, sort: 'end_date:asc'
    assert_response :success

    end_dates = dayoffs_in_list.map(&:end_date).compact
    assert_not_empty end_dates
    assert_equal end_dates.sort, end_dates
    assert_select 'table.dayoffs.sort-by-end-date.sort-asc'
  end

  def test_index_sort_by_end_date_desc
    @request.session[:user_id] = @admin.id
    compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, sort: 'end_date:desc'
    assert_response :success

    end_dates = dayoffs_in_list.map(&:end_date).compact
    assert_not_empty end_dates
    assert_equal end_dates.sort.reverse, end_dates
    assert_select 'table.dayoffs.sort-by-end-date.sort-desc'
  end

  # === Action :new ===

  def test_should_get_new_for_admin
    @request.session[:user_id] = @admin.id
    compatible_xhr_request :get, :new
    assert_response :success
  end

  def test_should_get_new_with_permission_edit_leave
    @request.session[:user_id] = @user.id
    PeopleAcl.create(@user.id, [:edit_leave])
    compatible_xhr_request :get, :new
    assert_response :success
  end

  def test_should_not_access_new_without_permission_edit_leave
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :new
    assert_response :forbidden
  end

  def test_should_not_access_new_for_anonymous
    compatible_xhr_request :get, :new
    assert_response :unauthorized
  end

  # === Action :create ===

  def test_should_create_dayoff_for_admin
    @request.session[:user_id] = @admin.id
    should_create_dayoff dayoff: @dayoff_params
  end

  def test_should_create_dayoff_with_permission_edit_leave
    @request.session[:user_id] = @user.id
    PeopleAcl.create(@user.id, [:edit_leave])
    should_create_dayoff dayoff: @dayoff_params
  end

  def test_should_not_create_dayoff_without_permission_edit_leave
    @request.session[:user_id] = @user.id
    should_not_create_dayoff :forbidden, dayoff: @dayoff_params
  end

  def test_should_not_create_dayoff_for_anonymous
    should_not_create_dayoff :unauthorized, dayoff: @dayoff_params
  end

  def test_should_not_create_dayoff_without_user
    @request.session[:user_id] = @admin.id
    should_not_create_dayoff :success, dayoff: @dayoff_params.merge(user_id: nil)
  end

  def test_should_not_create_dayoff_without_leave_type
    @request.session[:user_id] = @admin.id
    should_not_create_dayoff :success, dayoff: @dayoff_params.merge(leave_type_id: nil)
  end

  def test_should_not_create_dayoff_without_start_date
    @request.session[:user_id] = @admin.id
    should_not_create_dayoff :success, dayoff: @dayoff_params.merge(start_date: nil)
  end

  def test_should_not_create_dayoff_when_end_date_greater_than_start_date
    @request.session[:user_id] = @admin.id
    should_not_create_dayoff :success, dayoff: @dayoff_params.merge(end_date: '2019-01-01')
  end

  def test_should_send_mail_after_create_dayoff
    @request.session[:user_id] = @admin.id
    ActionMailer::Base.deliveries.clear
    should_create_dayoff dayoff: @dayoff_params
    assert ActionMailer::Base.deliveries.present?
  end

  # === Action :edit ===

  def test_should_get_edit_for_admin
    @request.session[:user_id] = @admin.id
    compatible_xhr_request :get, :edit, id: 1
    assert_response :success
  end

  def test_should_get_edit_with_permission_edit_leave
    @request.session[:user_id] = @user.id
    PeopleAcl.create(@user.id, [:edit_leave])
    compatible_xhr_request :get, :edit, id: 1
    assert_response :success
  end

  def test_should_not_access_edit_without_permission_edit_leave
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :edit, id: 1
    assert_response :forbidden
  end

  def test_should_not_access_edit_for_anonymous
    compatible_xhr_request :get, :edit, id: 1
    assert_response :unauthorized
  end

  def test_should_not_access_edit_for_missing_dayoff
    @request.session[:user_id] = @admin.id
    compatible_xhr_request :get, :edit, id: 777
    assert_response :missing
  end

  # === Action :update ===

  def test_should_update_dayoff_for_admin
    @request.session[:user_id] = @admin.id
    should_update_dayoff id: 1, dayoff: @dayoff_params
  end

  def test_should_update_dayoff_with_permission_edit_leave
    @request.session[:user_id] = @user.id
    PeopleAcl.create(@user.id, [:edit_leave])
    should_update_dayoff id: 1, dayoff: @dayoff_params
  end

  def test_should_not_update_dayoff_without_permission_edit_leave
    @request.session[:user_id] = @user.id
    should_not_update_dayoff :forbidden, id: 1, dayoff: @dayoff_params
  end

  def test_should_not_update_dayoff_for_anonymous
    should_not_update_dayoff :unauthorized, id: 1, dayoff: @dayoff_params
  end

  def test_should_not_update_dayoff_without_user
    @request.session[:user_id] = @admin.id
    should_not_update_dayoff :success, id: 1, dayoff: @dayoff_params.merge(user_id: nil)
  end

  def test_should_not_update_dayoff_without_leave_type
    @request.session[:user_id] = @admin.id
    should_not_update_dayoff :success, id: 1, dayoff: @dayoff_params.merge(leave_type_id: nil)
  end

  def test_should_not_update_dayoff_without_start_date
    @request.session[:user_id] = @admin.id
    should_not_update_dayoff :success, id: 1, dayoff: @dayoff_params.merge(start_date: nil)
  end

  def test_should_not_update_dayoff_when_end_date_greater_than_start_date
    @request.session[:user_id] = @admin.id
    should_not_update_dayoff :success, id: 1, dayoff: @dayoff_params.merge(end_date: '2019-01-01')
  end

  # === Action :destroy ===

  def test_should_destroy_dayoff_for_admin
    @request.session[:user_id] = @admin.id
    should_destroy_dayoff(id: 1)
  end

  def test_should_destroy_dayoff_with_permission_edit_leave
    @request.session[:user_id] = @user.id
    PeopleAcl.create(@user.id, [:edit_leave])
    should_destroy_dayoff(id: 1)
  end

  def test_should_not_destroy_dayoff_without_permission_edit_leave
    @request.session[:user_id] = @user.id
    assert_difference('Dayoff.count', 0) do
      compatible_request :delete, :destroy, id: 1
    end
    assert_response :forbidden
  end

  def test_should_not_destroy_dayoff_for_anonymous
    assert_difference('Dayoff.count', 0) do
      compatible_request :delete, :destroy, id: 1
    end
    assert_response :redirect
  end

  private

  def should_get_dayoffs_chart_with_grouping_by(group_by)
    return if Rails.version < '4.1' # travel_to helper added in Rails  4.1

    @request.session[:user_id] = @admin.id
    travel_to Date.new(2019, 7, 1) do
      compatible_request :get, :index, group_by: group_by
      assert_response :success
      assert_select '.leave-planner-chart' do
        assert_select '.leave-planner-subjects .group-container > .group-subject'
        assert_select '.leave-planner-subjects .group-container > .group'
      end
    end
  end

  def should_get_dayoffs_list_with_grouping_by(group_by)
    return if Rails.version < '4.1' # travel_to helper added in Rails  4.1

    @request.session[:user_id] = @admin.id
    travel_to Date.new(2019, 7, 1) do
      compatible_request :get, :index, list_style: DayoffQuery::TABLE_STYLE, group_by: group_by
      assert_response :success
      assert_select 'table.dayoffs.list' do
        assert_select 'tr.group'
        assert_select 'tr.dayoff'
      end
    end
  end

  def should_create_dayoff(params)
    assert_difference('Dayoff.count') do
      compatible_xhr_request :post, :create, params
    end
    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_create)
  end

  def should_not_create_dayoff(response_status, params)
    assert_difference('Dayoff.count', 0) do
      compatible_xhr_request :post, :create, params
    end
    assert_response response_status
  end

  def should_update_dayoff(params)
    compatible_xhr_request :post, :update, params
    dayoff = Dayoff.find(params[:id])
    params[:dayoff].each do |attr, val|
      assert_equal dayoff.send(attr), val, "Incorrect dayoff attribute: #{attr}"
    end
    assert_response :success
    assert_equal flash[:notice], l(:notice_successful_update)
  end

  def should_not_update_dayoff(response_status, params)
    dayoff = Dayoff.find(1)
    compatible_xhr_request :post, :update, params
    assert_response response_status
    assert_equal dayoff.updated_at, dayoff.reload.updated_at
  end

  def should_destroy_dayoff(params)
    assert_difference('Dayoff.count', -1) do
      compatible_request :delete, :destroy, params
    end
    assert_redirected_to dayoffs_path
    assert_equal flash[:notice], l(:notice_successful_delete)
  end
end
