require File.expand_path('../../test_helper', __FILE__)

class IssuesReportTemplatesControllerTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers,
           :issue_categories, :enabled_modules, :enumerations, :attachments, :workflows

  create_fixtures(Redmine::Plugin.find(:redmine_reporter).directory + '/test/fixtures/', [:report_templates, :queries])

  def setup
    @admin = User.find(1)
    @user = User.find(2)

    # Attachments of Issue(1) not on disk
    # Attachments of Issue(14) exist on disk
    @issue_ids = [1, 14]
  end

  # === Action :new ===

  def test_should_get_new_for_admin
    @request.session[:user_id] = @admin.id
    check_get_new
  end

  def test_should_get_new_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :generate_issue_reports
    check_get_new
  end

  def test_should_not_get_new_without_permission
    @request.session[:user_id] = @user.id
    check_get_new :forbidden
  end

  def test_should_not_get_new_for_anonymous
    check_get_new :unauthorized
  end

  # === Action :create ===

  def test_should_create_issues_reports_for_admin
    @request.session[:user_id] = @admin.id
    check_create_issues_reports
  end

  def test_should_create_issues_reports_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :generate_issue_reports
    check_create_issues_reports
  end

  def test_should_not_create_issues_reports_without_permission
    @request.session[:user_id] = @user.id
    check_create_issues_reports :forbidden
  end

  def test_should_not_create_issues_reports_for_anonymous
    check_create_issues_reports :redirect
  end

  def test_should_create_issues_reports_by_token_for_anonymous_with_login_required
    with_settings(login_required: '1') { check_create_issues_reports_by_token }
  end

  # === Action :autocomplete ===

  def test_should_get_autocomplete_for_admin
    @request.session[:user_id] = @admin.id
    check_get_autocomplete
  end

  def test_should_get_autocomplete_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :generate_issue_reports
    check_get_autocomplete
  end

  def test_should_not_get_autocomplete_without_permission
    @request.session[:user_id] = @user.id
    compatible_xhr_request :get, :autocomplete, q: ''
    assert_response :forbidden
  end

  def test_should_not_get_autocomplete
    compatible_xhr_request :get, :autocomplete, q: ''
    assert_response :unauthorized
  end

  # === Action :attach ===

  def test_should_attach_reports_for_admin
    @request.session[:user_id] = @admin.id
    should_attach_reports
  end

  def test_should_attach_reports_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :generate_issue_reports
    should_attach_reports
  end

  def test_should_not_attach_reports_without_permission
    @request.session[:user_id] = @user.id
    should_not_attach_reports
  end

  def test_should_not_attach_reports
    should_not_attach_reports :redirect
  end

  # === Action :preview ===

  def test_should_get_preview_for_admin
    @request.session[:user_id] = @admin.id
    check_get_preview
  end

  def test_should_get_preview_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :view_issue_reports
    check_get_preview
  end

  def test_should_not_get_preview_without_permission
    @request.session[:user_id] = @user.id
    check_get_preview :forbidden
  end

  def test_should_not_get_preview_for_anonymous
    check_get_preview :redirect
  end

  def test_should_get_preview_by_token_for_admin
    @request.session[:user_id] = @admin.id
    check_get_preview_by_token
  end

  def test_should_get_preview_by_token_for_logged_user
    @request.session[:user_id] = @user.id
    check_get_preview_by_token
  end

  def test_should_get_preview_by_token_for_anonymous
    check_get_preview_by_token
  end

  def test_should_get_preview_by_token_for_anonymous_with_login_required
    with_settings(login_required: '1') { check_get_preview_by_token }
  end

  private

  # === Helpers for action :new ===

  def get_new(parameters, response_status)
    compatible_xhr_request :get, :new, parameters
    assert_response response_status
    assert_match /ajax-modal/, response.body if response_status == :success
  end

  def check_get_new(response_status = :success)
    # Request from issue view (link 'Reports')
    @issue_ids.each do |issue_id|
      get_new({ issue_id: issue_id }, response_status)
    end

    # Request from issues list view (context menu 'Reports')
    get_new({ issue_ids: @issue_ids }, response_status)
  end

  # === Helpers for action :create ===

  def create_issues_reports(parameters, filename, file_type, response_status)
    compatible_request :post, :create, parameters
    assert_response response_status
    if response_status == :success
      assert_equal "application/#{file_type}", @response.content_type
      assert_equal %(attachment; filename="#{filename}"), @response.headers['Content-Disposition']
    end
  end

  def check_create_issues_reports(response_status = :success)
    # Creating reports for issue
    @issue_ids.each do |issue_id|
      issue = Issue.find(issue_id)
      [1, 5].each do |template_id|
        report_template = ReportTemplate.find(template_id)
        create_issues_reports({ issue_ids: [issue], report_template: { ids: [report_template] } }, report_template.filename('.pdf', issue: issue), 'pdf', response_status)
      end
    end

    # Creating reports for issues
    create_issues_reports({ issue_ids: @issue_ids, report_template: { ids: [1, 2] } }, 'issues reports.zip', 'zip', response_status)
  end

  def check_create_issues_reports_by_token
    @issue_ids.each do |issue_id|
      issue = Issue.find(issue_id)
      report_template = ReportTemplate.find(5)
      create_issues_reports(
        { issue_ids: [issue], report_template: { ids: [report_template] }, token: RedmineReporter.token([issue.id], [report_template.id]) },
        report_template.filename('.pdf', issue: issue),
        'pdf',
        :forbidden
      )
    end

    create_issues_reports({ issue_ids: @issue_ids, report_template: { ids: [1] }, token: RedmineReporter.token(@issue_ids, [1]) }, 'issues reports.zip', 'zip', :forbidden)

    with_settings plugin_redmine_reporter: { 'public_links' => '1' } do
      create_issues_reports({ issue_ids: @issue_ids, report_template: { ids: [1] }, token: '' }, 'issues reports.zip', 'zip', :forbidden)
      create_issues_reports({ issue_ids: @issue_ids, report_template: { ids: [1] }, token: RedmineReporter.token(@issue_ids, [1]) }, 'issues reports.zip', 'zip', :success)
      create_issues_reports({ issue_ids: @issue_ids, report_template: { ids: [1, 3] }, token: RedmineReporter.token(@issue_ids, [1, 3]) }, 'issues reports.zip', 'zip', :success)
    end
  end

  # === Helpers for action :autocomplete ===

  def get_autocomplete(parameters, report_template_ids = [])
    compatible_xhr_request :get, :autocomplete, parameters
    assert_response :success

    if report_template_ids.empty?
      assert @response.body.blank?
    else
      assert_select 'input', count: report_template_ids.size
      report_template_ids.each { |id| assert_select %(input[name=?][value="#{id}"]), 'report_template[ids][]' }
    end
  end

  def check_get_autocomplete
    # Report templates for issue
    get_autocomplete({ issue_id: 1, q: '' }, [1, 2, 5])
    get_autocomplete({ issue_id: 1, q: 'example' }, [1])
    get_autocomplete({ issue_id: 1, q: 'list' }, [])

    # Report templates for issues
    get_autocomplete({ q: ''}, [1, 2, 3, 4, 5])
    get_autocomplete({ q: 'example'}, [1, 3])
    get_autocomplete({ q: 'list'}, [3, 4])
  end

  # === Helpers for action :attach ===

  def should_attach(referer, parameters)
    set_tmp_attachments_directory
    @request.env['HTTP_REFERER'] = referer
    issue = Issue.find(parameters[:issue_ids].sort.first)

    assert_difference(-> { issue.journals.size}, 1) do
      assert_difference(-> { issue.attachments.size }, parameters[:report_template][:ids].size) do
        compatible_request :post, :attach, parameters
        issue.reload
      end
    end
    assert_equal flash[:notice], l(:notice_successful_update)
    assert_redirected_to referer
  end

  def should_not_attach(referer, response_status, parameters)
    set_tmp_attachments_directory
    @request.env['HTTP_REFERER'] = referer
    issue = Issue.find(parameters[:issue_ids].sort.first)

    assert_difference(-> { issue.journals.size }, 0) do
      assert_difference(-> { issue.attachments.size }, 0) do
        compatible_request :post, :attach, parameters
        issue.reload
      end
    end
    assert_response response_status
  end

  def should_attach_reports
    # Attach reports to an issue
    @issue_ids.each do |issue_id|
      should_attach issue_path(issue_id), issue_ids: [issue_id], report_template: { ids: [1] }
      should_attach issue_path(issue_id), issue_ids: [issue_id], report_template: { ids: [5] }
    end
    # Attach reports to the first issue in issues
    should_attach issues_path, issue_ids: @issue_ids, report_template: { ids: [1, 3] }
  end

  def should_not_attach_reports(response_status = :forbidden)
    @issue_ids.each do |issue_id|
      should_not_attach issue_path(issue_id), response_status, issue_ids: [issue_id], report_template: { ids: [1] }
    end
    should_not_attach issues_path, response_status, issue_ids: @issue_ids, report_template: { ids: [1, 3] }
  end

  # === Helpers for action :preview ===

  def get_preview(parameters, response_status = :success)
    compatible_request :get, :preview, parameters
    assert_response response_status
  end

  def check_get_preview(response_status = :success)
    @issue_ids.each do |issue_id|
      get_preview({ issue_ids: [issue_id], report_template: { ids: [1] } }, response_status)
      get_preview({ issue_ids: [issue_id], report_template: { ids: [5] } }, response_status)
    end
    get_preview({ issue_ids: @issue_ids, report_template: { ids: [1, 3] } }, response_status)
    get_preview({ query_id: 1, report_template: { ids: [1, 3] } }, response_status)
  end

  def check_get_preview_by_token
    @issue_ids.each do |issue_id|
      get_preview({ issue_ids: [issue_id], token: '', report_template: { ids: [1] } }, :forbidden)
    end
    get_preview({ issue_ids: @issue_ids, token: RedmineReporter.token(@issue_ids, [1]), report_template: { ids: [1] } }, :forbidden)

    with_settings plugin_redmine_reporter: { 'public_links' => '1' } do
      @issue_ids.each do |issue_id|
        get_preview({ issue_ids: [issue_id], token: '', report_template: { ids: [1] } }, :forbidden)
        get_preview issue_ids: [issue_id], token: RedmineReporter.token([issue_id], [1]), report_template: { ids: [1] }
        get_preview issue_ids: [issue_id], token: RedmineReporter.token([issue_id], [5]), report_template: { ids: [5] }
      end

      get_preview issue_ids: @issue_ids, token: RedmineReporter.token(@issue_ids, [1, 3]), report_template: { ids: [1, 3] }
      get_preview query_id: 1, token: ReportTemplate.public_link_token(nil, [1, 3], 1), report_template: { ids: [1, 3] }
    end
  end
end
