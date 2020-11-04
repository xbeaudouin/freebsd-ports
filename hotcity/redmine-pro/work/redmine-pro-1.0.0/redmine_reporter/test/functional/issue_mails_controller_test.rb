require File.expand_path('../../test_helper', __FILE__)

class IssueMailsControllerTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers,
           :issue_categories, :enabled_modules, :enumerations, :attachments, :workflows

  fixtures :email_addresses if Redmine::VERSION.to_s >= '3.0'

  create_fixtures(Redmine::Plugin.find(:redmine_reporter).directory + '/test/fixtures/', [:report_templates])

  def setup
    @admin = User.find(1)
    @user = User.find(2)
  end

  # === Action :new ===

  def test_should_get_new_for_admin
    @request.session[:user_id] = @admin.id
    should_get_new
  end

  def test_should_get_new_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :send_issues
    should_get_new
  end

  def test_should_not_get_new_without_permission
    @request.session[:user_id] = @user.id
    should_not_get_new :forbidden
  end

  def test_should_not_get_new_for_anonymous
    should_not_get_new :unauthorized
  end

  # === Action :send_mail ===

  def test_should_send_mail_issue_reports_for_admin
    @request.session[:user_id] = @admin.id
    check_send_mail_issue_reports_success
    check_send_mail_issue_reports_failure
  end

  def test_should_send_mail_issue_reports_with_permission
    @request.session[:user_id] = @user.id
    Role.find(1).add_permission! :send_issues
    check_send_mail_issue_reports_success
    check_send_mail_issue_reports_failure
  end

  def test_should_not_send_mail_issue_reports_without_permission
    @request.session[:user_id] = @user.id
    should_not_send_mail_issue_reports({ issue_id: 1, issue_mail: build_issue_mail_params }, :forbidden)
  end

  def test_should_not_send_mail_issue_reports_for_anonymous
    should_not_send_mail_issue_reports({ issue_id: 1, issue_mail: build_issue_mail_params }, :redirect)
  end

  private

  # === Helpers for action :new ===

  def should_get_new
    compatible_xhr_request :get, :new, issue_id: 1, report_template: { ids: [1, 2, 3] }
    assert_response :success
    assert_select '#message-form', count: 1
    assert_select '#attachments_form span[id^=attachments_p]', count: 3
  end

  def should_not_get_new(response_status)
    compatible_xhr_request :get, :new, issue_id: 1, report_template: { ids: [1, 2, 3] }
    assert_response response_status
  end

  # === Helpers for action :send_mail ===

  def should_send_mail_issue_reports(parameters)
    ActionMailer::Base.deliveries.clear
    assert_difference(-> { ActionMailer::Base.deliveries.size }) do
      compatible_request :post, :send_mail, parameters
      assert_redirected_to issue_path(parameters[:issue_id])
      assert_equal flash[:notice], l(:notice_email_sent, parameters[:issue_mail][:to])
    end
  end

  def should_not_send_mail_issue_reports(parameters, response_status = :success)
    ActionMailer::Base.deliveries.clear
    assert_difference(-> { ActionMailer::Base.deliveries.size }, 0) do
      compatible_request :post, :send_mail, parameters
      assert_response response_status
    end
  end

  def build_issue_mail_params
    issue = Issue.find(1)
    reports = ReportTemplate.find(1, 3).map { |template| template.generate_reports([issue]) }.flatten
    saved_attachments = {}
    reports.map(&:create_attachment).each_with_index do |attachment, i|
      saved_attachments["p#{i}"] = { 'token' => attachment.token }
    end

    {
      from: @admin.mail,
      to: 'example@mail.com',
      cc: @admin.mail,
      bcc: 'bcc-email@mail.com',
      subject: 'Test',
      message: 'Test issue reports',
      attachments: saved_attachments
    }
  end

  def check_send_mail_issue_reports_success
    issue_mail_params = build_issue_mail_params
    should_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params.slice(:from, :to, :subject, :message)
    should_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params.except(:cc, :bcc, :attachments)
    should_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params
  end

  def check_send_mail_issue_reports_failure
    issue_mail_params = build_issue_mail_params
    should_not_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params.except(:to)
    should_not_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params.merge(from: '')
    should_not_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params.merge(from: '@')
    should_not_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params.merge(from: 'admin')
    should_not_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params.merge(to: 'admin@')
    should_not_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params.merge(cc: 'mail')
    should_not_send_mail_issue_reports issue_id: 1, issue_mail: issue_mail_params.merge(bcc: 'mail.com')
  end
end
