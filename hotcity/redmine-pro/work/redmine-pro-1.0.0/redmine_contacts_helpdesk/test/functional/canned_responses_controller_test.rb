require File.expand_path('../../test_helper', __FILE__)

class CannedResponsesControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages,
                                                                                                                             :canned_responses,
                                                                                                                             :helpdesk_tickets])

  def setup
    RedmineHelpdesk::TestCase.prepare
    @request.session[:user_id] = 1
  end

  def test_should_get_index
    compatible_request :get, :index, :project_id => 1
    assert_response 200
  end

  def test_should_get_new
    compatible_request :get, :new, :project_id => 1
    assert_response 200
  end

  def test_get_new_form_should_allow_attachment_upload
    compatible_request :get, :new
    assert_response :success
    assert_select 'form[id=new_canned_response][method=post][enctype="multipart/form-data"]' do
      assert_select 'input[name=?][type=file]', 'attachments[dummy][file]'
    end
  end

  def test_should_get_edit
    compatible_request :get, :edit, :id => 1
    assert_response 200
  end

  def test_edit_form_should_allow_attachment_upload
    compatible_request :get, :edit, id: 1
    assert_response :success
    assert_select 'form[id=edit_canned_response][method=post][enctype="multipart/form-data"]' do
      assert_select 'input[name=?][type=file]', 'attachments[dummy][file]'
    end
  end

  def test_should_post_create
    compatible_request :post, :create, :canned_response => { :name => 'New canned response', :content => 'Hi there!', :is_public => false }, :project_id => 1
    assert_redirected_to settings_project_path(Project.find('ecookbook'), :tab => 'helpdesk_canned_responses')
    assert_equal 'New canned response', CannedResponse.last.name
  end

  def test_post_create_with_attachment
    set_tmp_attachments_directory

    assert_difference 'CannedResponse.count' do
      assert_difference 'Attachment.count' do
        compatible_request :post, :create, {
          canned_response: {
            name: 'New canned response',
            content: 'Hi there!',
            is_public: false
          },
          attachments: {
            '1' => {
              'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file'}
          }
        }
      end
    end

    canned_response = CannedResponse.order('id DESC').first
    attachment = Attachment.order('id DESC').first

    assert_equal canned_response, attachment.container
    assert_equal 1, attachment.author_id
    assert_equal 'testfile.txt', attachment.filename
    assert_equal 'text/plain', attachment.content_type
    assert_equal 'test file', attachment.description
    assert_equal 59, attachment.filesize
    assert File.exists?(attachment.diskfile)
    assert_equal 59, File.size(attachment.diskfile)
  end

  def test_should_put_update
    compatible_request :put, :update, :id => 1, :canned_response => { :name => 'New name' }
    assert_redirected_to settings_project_path(Project.find('ecookbook'), :tab => 'helpdesk_canned_responses')
    assert_equal 'New name', CannedResponse.find(1).name
  end

  def test_put_update_with_attachment_deletion
    set_tmp_attachments_directory

    canned_response = CannedResponse.find(1)
    attachment = Attachment.first.copy(container: canned_response)
    attachment.save
    assert_equal 1, canned_response.attachments.size

    compatible_request :put, :update, id: 1, canned_response: { name: 'New name', deleted_attachment_ids: [attachment.id.to_s] }
    assert_equal 0, canned_response.attachments.size
  end

  def test_should_delete_destroy
    compatible_request :delete, :destroy, :id => 1
    assert_redirected_to settings_project_path(Project.find('ecookbook'), :tab => 'helpdesk_canned_responses')
    assert_nil CannedResponse.find_by_id(1)
  end

  def test_should_get_add
    compatible_xhr_request :get, :add, :id => 1, :project_id => 1, :issue_id => 1
    assert_response 200
  end
end
