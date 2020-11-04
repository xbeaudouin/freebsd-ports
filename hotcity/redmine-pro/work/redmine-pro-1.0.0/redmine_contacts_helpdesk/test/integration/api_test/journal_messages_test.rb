require File.expand_path('../../../test_helper', __FILE__)
# require File.dirname(__FILE__) + '/../../../../../test/test_helper'

class Redmine::ApiTest::JournalMessagesTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
  include RedmineHelpdesk::TestHelper

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

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages,
                                                                                                                             :helpdesk_tickets])

  def setup
    Setting.rest_api_enabled = '1'
    RedmineHelpdesk::TestCase.prepare
    @issue = Issue.find(1)
  end

  def test_create_journal_message_returns_validation_errors
    params_with_validation_errors.each do |test_case|
      Redmine::ApiTest::Base.should_allow_api_authentication(:post, '/journal_messages.json',
                                                             test_case[:params],
                                                             success_code: :created) if ActiveRecord::VERSION::MAJOR < 4
      compatible_api_request :post, '/journal_messages.json', test_case[:params], credentials('admin')

      assert_response test_case[:code]
      if Redmine::VERSION.to_s >= '2.7'
        assert_equal JSON.parse(@response.body), { 'errors' => [test_case[:error]] }
      else
        assert JSON.parse(@response.body)['errors'].any?
      end
    end
  end

  def test_post_create_journal_message
    ActionMailer::Base.deliveries.clear
    Redmine::ApiTest::Base.should_allow_api_authentication(:post, '/journal_messages.json',
                                                           journal_message_params,
                                                           success_code: :created) if ActiveRecord::VERSION::MAJOR < 4

    assert_difference('Journal.count') do
      compatible_api_request :post, '/journal_messages.json', journal_message_params, credentials('admin')
    end

    journal = @issue.journals.last
    assert_equal 'from@email.com', journal.journal_message.from_address
    assert_equal 'to@email.com', journal.journal_message.to_address
    assert_equal 'cc@email.com', journal.journal_message.cc_address
    assert_equal 'bcc@email.com', journal.journal_message.bcc_address
    assert_equal 'API text', journal.notes

    assert_response :created
    assert_equal 'application/json', @response.content_type
    assert_equal journal_message_response(journal), JSON.parse(@response.body)
  end


  private

  def params_with_validation_errors
    [
      { params: {}, code: 404, error: 'Issue not found' }, # empty params
      { params: { journal_message: {} }, code: 404, error: 'Issue not found' },
      { params: { journal_message: { issue_id: @issue.id, content: {} } }, code: 422, error: 'Content data cannot be blank' }
    ]
  end

  def journal_message_params
    {
      journal_message: {
        issue_id: @issue.id,
        from_address: 'from@email.com',
        to_address: 'to@email.com',
        cc_address: 'cc@email.com',
        bcc_address: 'bcc@email.com',
        content: 'API text'
      }
    }
  end

  def journal_message_response(journal)
    {
      'journal_message' => {
        'id' => journal.id,
        'from_address' => 'from@email.com',
        'to_address' => 'to@email.com',
        'cc_address' => 'cc@email.com',
        'bcc_address' => 'bcc@email.com',
        'content' => 'API text',
        'message_date' => ::I18n.l(journal.journal_message.message_date.to_date),
        'message_id' => journal.journal_message.message_id
      }
    }
  end
end
