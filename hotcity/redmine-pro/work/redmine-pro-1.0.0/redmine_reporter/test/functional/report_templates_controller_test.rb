require File.expand_path('../../test_helper', __FILE__)

class ReportTemplatesControllerTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers,
           :issue_categories, :enabled_modules, :enumerations, :attachments, :workflows

  create_fixtures(Redmine::Plugin.find(:redmine_reporter).directory + '/test/fixtures/', [:report_templates])

  def setup
    @admin = User.find(1)
    @user = User.find(2)
    @project = Project.find(1)
    @redmine_reporter_settings_path = plugin_settings_path(Redmine::Plugin.find(:redmine_reporter), tab: 'report_templates')
    @report_template_params = {
      type: 'IssueReportTemplate',
      name: 'Issue report example',
      description: 'Issue report template description.',
      content: '<h1>Issue report example</h1><hr>{{issue.subject}}',
      report_template_is_for_all: false
    }
  end

  # === Action :new ===

  def test_should_get_new_for_admin
    @request.session[:user_id] = @admin.id
    compatible_request :get, :new
    assert_response :success

    compatible_request :get, :new, project_id: @project.identifier
    assert_response :success
  end

  def test_should_get_new_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :manage_report_templates

    compatible_request :get, :new
    assert_response :success

    compatible_request :get, :new, project_id: @project.identifier
    assert_response :success
  end

  def test_should_not_access_new_without_permission
    @request.session[:user_id] = @user.id
    compatible_request :get, :new
    assert_response :forbidden

    compatible_request :get, :new, project_id: @project.identifier
    assert_response :forbidden
  end

  def test_should_not_access_new_for_anonymous
    compatible_request :get, :new
    assert_response :redirect

    compatible_request :get, :new, project_id: @project.identifier
    assert_response :redirect
  end

  # === Action :create ===

  def test_should_create_issue_report_template_for_admin
    @request.session[:user_id] = @admin.id
    should_create_report_template
  end

  def test_should_create_issue_list_report_template_for_admin
    @request.session[:user_id] = @admin.id
    @report_template_params.update type: 'IssueListReportTemplate', report_template_is_for_all: true
    should_create_report_template
  end

  def test_should_create_report_template_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :manage_report_templates
    should_create_report_template
  end

  def test_should_not_create_report_template_without_permission
    @request.session[:user_id] = @user.id
    should_not_create_report_template :forbidden
  end

  def test_should_not_create_report_template
    should_not_create_report_template
  end

  # === Action :edit ===

  def test_should_get_edit_for_admin
    @request.session[:user_id] = @admin.id
    compatible_request :get, :edit, id: 1
    assert_response :success
  end

  def test_should_get_edit_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :manage_report_templates
    compatible_request :get, :edit, id: 1
    assert_response :success
  end

  def test_should_not_access_edit_without_permission
    @request.session[:user_id] = @user.id
    compatible_request :get, :edit, id: 1
    assert_response :forbidden
  end

  def test_should_not_access_edit
    compatible_request :get, :edit, id: 1
    assert_response :redirect
  end

  # === Action :update ===

  def test_should_update_report_template_for_admin
    @request.session[:user_id] = @admin.id
    should_update_report_template
  end

  def test_should_update_report_template_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :manage_report_templates
    should_update_report_template
  end

  def test_should_not_update_without_permission
    @request.session[:user_id] = @user.id
    should_not_update_report_template :forbidden
  end

  def test_should_not_update_report_template
    should_not_update_report_template
  end

  # === Action :destroy ===

  def test_should_destroy_report_template_for_admin
    @request.session[:user_id] = @admin.id
    should_destroy_report_template
  end

  def test_should_destroy_report_template_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :manage_report_templates
    should_destroy_report_template
  end

  def test_should_not_destroy_report_template_without_permission
    @request.session[:user_id] = @user.id
    should_not_destroy_report_template :forbidden
  end

  def test_should_not_destroy_report_template
    should_not_destroy_report_template
  end

  # === Action :export ===

  def test_should_export_report_template_for_admin
    @request.session[:user_id] = @admin.id
    should_export_report_template
  end

  def test_should_export_report_template_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :manage_report_templates
    should_export_report_template
  end

  def test_should_not_export_report_template_without_permission
    @request.session[:user_id] = @user.id
    should_not_export_report_template :forbidden
  end

  def test_should_not_export_report_template
    should_not_export_report_template
  end

  # === Action :new_import ===

  def test_should_access_new_import_for_admin
    @request.session[:user_id] = @admin.id
    compatible_request :get, :new_import
    assert_response :success
  end

  def test_should_access_new_import_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :manage_report_templates
    compatible_request :get, :new_import
    assert_response :success
  end

  def test_should_not_access_new_import_without_permission
    @request.session[:user_id] = @user.id
    compatible_request :get, :new_import
    assert_response :forbidden
  end

  def test_should_not_access_new_import
    compatible_request :get, :new_import
    assert_response :redirect
  end

  # === Action :import ===

  def test_should_import_for_admin
    @request.session[:user_id] = @admin.id
    should_import
  end

  def test_should_import_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :manage_report_templates
    should_import
  end

  def test_should_not_import_without_permission
    @request.session[:user_id] = @user.id
    should_not_import :forbidden
  end

  def test_should_not_import
    should_not_import
  end

  private

  def should_create_report_template(params = @report_template_params)
    # Creating from plugin settings
    assert_difference('ReportTemplate.count') do
      compatible_request :post, :create, report_template: params
    end
    assert_redirected_to @redmine_reporter_settings_path
    assert_equal flash[:notice], l(:notice_successful_create)

    # Creating from project settings
    assert_difference('ReportTemplate.count') do
      compatible_request :post, :create, report_template: params, project_id: @project.identifier
    end
    assert_redirected_to settings_project_path(@project, tab: 'report_templates')
    assert_equal flash[:notice], l(:notice_successful_create)
  end

  def should_not_create_report_template(response_status = :redirect, params = @report_template_params)
    # Creating from plugin settings
    assert_difference('ReportTemplate.count', 0) do
      compatible_request :post, :create, report_template: params
    end
    assert_response response_status

    # Creating from project settings
    assert_difference('ReportTemplate.count', 0) do
      compatible_request :post, :create, report_template: params, project_id: @project.identifier
    end
    assert_response response_status
  end

  def should_update_report_template
    # Updating from plugin settings
    new_attributes = { type: 'IssueListReportTemplate', name: 'Issue List report example' }
    compatible_request :post, :update, id: 1, report_template: new_attributes
    report_template = ReportTemplate.find(1)
    new_attributes.each { |attr, val| assert_equal report_template.send(attr), val }
    assert_redirected_to @redmine_reporter_settings_path
    assert_equal flash[:notice], l(:notice_successful_update)

    # Updating from project settings
    new_attributes = { type: 'IssueReportTemplate', name: 'Issue report example' }
    compatible_request :post, :update, id: 2, report_template: new_attributes, project_id: @project.identifier
    report_template = ReportTemplate.find(2)
    new_attributes.each { |attr, val| assert_equal report_template.send(attr), val }
    assert_redirected_to settings_project_path(@project, tab: 'report_templates')
    assert_equal flash[:notice], l(:notice_successful_update)
  end

  def should_not_update_report_template(response_status = :redirect)
    new_attributes = { type: 'IssueListReportTemplate', name: 'Issue List report example' }
    compatible_request :post, :update, id: 1, report_template: new_attributes
    assert_response response_status
    report_template = ReportTemplate.find(1)
    new_attributes.each { |attr, val| assert_not_equal report_template.send(attr), val }
  end

  def should_destroy_report_template
    # Deleting from plugin settings
    assert_difference('ReportTemplate.count', -1) do
      compatible_request :delete, :destroy, id: 1
    end
    assert_redirected_to @redmine_reporter_settings_path
    assert_equal flash[:notice], l(:notice_successful_delete)

    # Deleting from project settings
    assert_difference('ReportTemplate.count', -1) do
      compatible_request :delete, :destroy, id: 2, project_id: @project.identifier
    end
    assert_redirected_to settings_project_path(@project, tab: 'report_templates')
    assert_equal flash[:notice], l(:notice_successful_delete)
  end

  def should_not_destroy_report_template(response_status = :redirect)
    # Deleting from plugin settings
    assert_difference('ReportTemplate.count', 0) do
      compatible_request :delete, :destroy, id: 1
    end
    assert_response response_status

    # Deleting from project settings
    assert_difference('ReportTemplate.count', 0) do
      compatible_request :delete, :destroy, id: 1, project_id: @project.identifier
    end
    assert_response response_status
  end

  def should_export_report_template
    report_template = ReportTemplate.find(1)
    compatible_request :get, :export, id: report_template

    assert_response :success

    assert_match 'text/yaml', @response.content_type
    assert_equal %(attachment; filename="#{report_template.filename('.yml')}"), @response.headers['Content-Disposition']
    YAML.load(@response.body).each { |attr, val| assert_equal report_template.send(attr), val }
  end

  def should_not_export_report_template(response_status = :redirect)
    compatible_request :get, :export, id: 1
    assert_response response_status
  end

  def should_import
    new_report_file = Rack::Test::UploadedFile.new(redmine_reporter_fixture_files_path + 'new_issue_report_template.yml', 'text/yml')
    existing_report_file = Rack::Test::UploadedFile.new(redmine_reporter_fixture_files_path + 'existing_issue_report_template.yml', 'text/yml')

    # Import from plugin settings
    assert_difference('ReportTemplate.count') do
      compatible_request :post, :import, file: new_report_file
    end
    assert_redirected_to @redmine_reporter_settings_path
    assert_equal flash[:notice], l(:notice_reporter_import_success)

    # Import from project settings
    assert_difference('ReportTemplate.count', 0) do
      compatible_request :post, :import, file: existing_report_file, rewrite: 1, project_id: @project.identifier
    end
    assert_redirected_to settings_project_path(@project, tab: 'report_templates')
    assert_equal flash[:notice], l(:notice_reporter_import_success)
  end

  def should_not_import(response_status = :redirect)
    new_report_file = Rack::Test::UploadedFile.new(redmine_reporter_fixture_files_path + 'new_issue_report_template.yml', 'text/yml')

    # Import from plugin settings
    assert_difference('ReportTemplate.count', 0) do
      compatible_request :post, :import, file: new_report_file
    end
    assert_response response_status

    # Import from project settings
    assert_difference('ReportTemplate.count', 0) do
      compatible_request :post, :import, file: new_report_file, rewrite: 1, project_id: @project.identifier
    end
    assert_response response_status
  end
end
