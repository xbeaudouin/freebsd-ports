require File.expand_path('../../test_helper', __FILE__)

class TimeEntriesReportsControllerTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers,
           :issue_categories, :enabled_modules, :enumerations, :attachments, :workflows, :time_entries

  create_fixtures(Redmine::Plugin.find(:redmine_reporter).directory + '/test/fixtures/', [:report_templates, :queries])

  def setup
    @admin = User.find(1)
    @user = User.find(2)
  end

  # === Action :new ===

  def test_should_get_new_for_admin
    @request.session[:user_id] = @admin.id
    should_get_new time_entries: [1]
    should_get_new time_entries: [1, 2]
  end

  def test_should_get_new_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :generate_time_entries_reports
    should_get_new time_entries: [1, 2]
  end

  def test_should_not_get_new_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :new, time_entries: [1, 2]
    assert_response :forbidden
  end

  def test_should_not_get_new_for_anonymous
    compatible_xhr_request :get, :new, time_entries: [1, 2]
    assert_response :unauthorized
  end

  # === Action :create ===

  def test_should_create_time_entries_reports_for_admin
    @request.session[:user_id] = @admin.id
    check_create_time_entries_reports
  end

  def test_should_create_time_entries_reports_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :generate_time_entries_reports
    check_create_time_entries_reports
  end

  def test_should_not_create_time_entries_reports_without_permission
    @request.session[:user_id] = @user.id
    compatible_request :post, :create, time_entries_ids: [1], report_template: { ids: [6] }
    assert_response :forbidden
  end

  def test_should_not_create_time_entries_reports_for_anonymous
    compatible_request :post, :create, time_entries_ids: [1], report_template: { ids: [6] }
    assert_response :redirect
  end

  def test_should_create_time_entries_reports_by_token_for_anonymous_with_login_required
    with_settings(login_required: '1') do
      with_settings plugin_redmine_reporter: { 'public_links' => '1' } do
        check_create_time_entries_reports true
      end
    end
  end

  def test_should_not_create_time_entries_reports_by_token_without_public_links
    with_settings(login_required: '1') do
      compatible_request :post, :create, time_entries_ids: [1], report_template: { ids: [6] }, token: RedmineReporter.token([1], [6])
      assert_response :forbidden
    end
  end

  def test_should_not_create_time_entries_reports_with_invalid_token
    with_settings(login_required: '1') do
      with_settings plugin_redmine_reporter: { 'public_links' => '1' } do
        compatible_request :post, :create, time_entries_ids: [1], report_template: { ids: [6] }, token: ''
        assert_response :forbidden
      end
    end
  end

  # === Action :autocomplete ===

  def test_should_get_autocomplete_for_admin
    @request.session[:user_id] = @admin.id
    check_get_autocomplete
  end

  def test_should_get_autocomplete_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :generate_time_entries_reports
    check_get_autocomplete
  end

  def test_should_not_get_autocomplete_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :autocomplete, q: ''
    assert_response :forbidden
  end

  def test_should_not_get_autocomplete_for_anonymous
    compatible_xhr_request :get, :autocomplete, q: ''
    assert_response :unauthorized
  end

  # === Action :preview ===

  def test_should_get_preview_for_admin
    @request.session[:user_id] = @admin.id
    check_get_preview
  end

  def test_should_get_preview_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_time_entries_reports
    check_get_preview
  end

  def test_should_not_get_preview_without_permission
    @request.session[:user_id] = @user.id
    compatible_request :get, :preview, time_entries_ids: [1, 2], report_template: { ids: [6] }
    assert_response :forbidden
  end

  def test_should_not_get_preview_for_anonymous
    compatible_request :get, :preview, time_entries_ids: [1, 2], report_template: { ids: [6] }
    assert_response :redirect
  end

  def test_should_get_preview_by_token_for_admin
    @request.session[:user_id] = @admin.id
    with_settings plugin_redmine_reporter: { 'public_links' => '1' } do
      check_get_preview_by_token
    end
  end

  def test_should_get_preview_by_token_for_regular_user
    @request.session[:user_id] = @user.id
    with_settings plugin_redmine_reporter: { 'public_links' => '1' } do
      check_get_preview_by_token
    end
  end

  def test_should_get_preview_by_token_for_anonymous
    with_settings plugin_redmine_reporter: { 'public_links' => '1' } do
      check_get_preview_by_token
    end
  end

  def test_should_get_preview_by_token_for_anonymous_with_login_required
    with_settings(login_required: '1') do
      with_settings plugin_redmine_reporter: { 'public_links' => '1' } do
        check_get_preview_by_token
      end
    end
  end

  def test_should_not_get_preview_by_token_for_admin_without_public_links
    @request.session[:user_id] = @admin.id
    compatible_request :get, :preview, {
      time_entries_ids: [1, 2],
      report_template: { ids: [6, 7] },
      token: RedmineReporter.token([1, 2], [6])
    }

    assert_response :forbidden
  end

  def test_should_not_get_preview_by_token_for_anonymous_without_public_links
    compatible_request :get, :preview, {
      time_entries_ids: [1, 2],
      report_template: { ids: [6, 7] },
      token: RedmineReporter.token([1, 2], [6])
    }
    assert_response :forbidden
  end

  def test_should_not_get_preview_by_token_for_anonymous_with_invalid_token
    with_settings(login_required: '1') do
      with_settings plugin_redmine_reporter: { 'public_links' => '1' } do
        compatible_request :get, :preview, {
          time_entries_ids: [1, 2],
          report_template: { ids: [6] },
          token: ''
        }
        assert_response :forbidden
      end
    end
  end

  private

  # === Helpers for action :new ===

  def should_get_new(parameters)
    compatible_xhr_request :get, :new, parameters
    assert_response :success
    assert_match /ajax-modal/, response.body
  end

  # === Helpers for action :create ===

  def should_create_time_entries_reports(filename, file_type, parameters)
    compatible_request :post, :create, parameters
    assert_response :success
    assert_equal "application/#{file_type}", @response.content_type
    assert_equal %(attachment; filename="#{filename}"), @response.headers['Content-Disposition']
  end

  def check_create_time_entries_reports(token = false)
    report_template = ReportTemplate.find(6)
    params = { time_entries_ids: [1], report_template: { ids: [report_template.id] } }
    params[:token] = RedmineReporter.token([1], [report_template.id]) if token
    should_create_time_entries_reports report_template.filename, 'pdf', params

    params = { time_entries_ids: [1, 2], report_template: { ids: [6, 7] } }
    params[:token] = RedmineReporter.token([1, 2], [6, 7]) if token
    should_create_time_entries_reports 'time entries reports.zip', 'zip', params
  end

  # === Helpers for action :autocomplete ===

  def should_get_autocomplete(expected_report_template_ids, parameters)
    compatible_xhr_request :get, :autocomplete, parameters
    assert_response :success

    if expected_report_template_ids.empty?
      assert @response.body.blank?
    else
      assert_select 'input', count: expected_report_template_ids.size
      expected_report_template_ids.each do |id|
        assert_select %(input[name=?][value="#{id}"]), 'report_template[ids][]'
      end
    end
  end

  def check_get_autocomplete
    should_get_autocomplete [6, 7], q: ''
    should_get_autocomplete [6], q: 'example'
    should_get_autocomplete [7], q: 'second'
    should_get_autocomplete [], q: 'list'
  end

  # === Helpers for action :preview ===

  def should_get_preview(parameters)
    compatible_request :get, :preview, parameters
    assert_response :success
  end

  def check_get_preview
    should_get_preview time_entries_ids: [1], report_template: { ids: [6] }
    should_get_preview time_entries_ids: [1, 2], report_template: { ids: [6, 7] }
    should_get_preview query_id: 2, report_template: { ids: [6, 7] }
  end

  def check_get_preview_by_token
    should_get_preview time_entries_ids: [1], report_template: { ids: [6] }, token: RedmineReporter.token([1], [6])
    should_get_preview time_entries_ids: [1, 2], report_template: { ids: [6, 7] }, token: RedmineReporter.token([1, 2], [6, 7])
    should_get_preview query_id: 2, report_template: { ids: [6, 7] }, token: ReportTemplate.public_link_token(nil, [6, 7], 2)
  end
end
