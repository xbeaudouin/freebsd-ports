require File.expand_path('../../test_helper', __FILE__)

class ReporterAttachmentImagesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers,
           :issue_categories, :enabled_modules, :enumerations, :attachments

  create_fixtures(Redmine::Plugin.find(:redmine_reporter).directory + '/test/fixtures/', [:report_templates])

  def setup
    @admin = User.find(1)
    @attachment = ReporterAttachmentImage.find(17)
    set_fixtures_attachments_directory
  end

  def teardown
    set_tmp_attachments_directory
  end

  def test_should_download_for_admin
    @request.session[:user_id] = @admin.id
    should_download(@attachment)
  end

  def test_should_download_for_anonymous
    @request.session[:user_id] = nil
    should_download(@attachment)
  end

  def test_should_download_for_anonymous_with_login_required
    with_settings login_required: '1' do
      @request.session[:user_id] = nil
      should_download(@attachment)
    end
  end

  def test_should_not_download_by_incorrect_token_for_admin
    @request.session[:user_id] = @admin.id
    should_not_download(@attachment.public_link_params.merge(token: 'token'))
  end

  def test_should_not_download_by_incorrect_token_for_anonymous
    @request.session[:user_id] = nil
    should_not_download(@attachment.public_link_params.merge(token: 'token'), :redirect)
  end

  def test_should_return_404_on_download_for_admin
    @request.session[:user_id] = @admin.id
    params = @attachment.public_link_params
    should_not_download(params.merge(filename: 'file.png'), :missing)
    should_not_download(params.merge(id: 777), :missing)
  end

  def test_should_return_404_on_download_for_anonymous
    @request.session[:user_id] = nil
    params = @attachment.public_link_params
    should_not_download(params.merge(filename: 'file.png'), :missing)
    should_not_download(params.merge(id: 777), :missing)
  end

  private

  def should_download(attachment)
    compatible_request :get, :download, attachment.public_link_params
    assert_response :success
    assert_equal attachment.content_type, @response.content_type
    assert_equal %(attachment; filename="#{attachment.filename}"), @response.headers['Content-Disposition']
  end

  def should_not_download(params, response_status = :forbidden)
    compatible_request :get, :download, params
    assert_response response_status
  end
end
