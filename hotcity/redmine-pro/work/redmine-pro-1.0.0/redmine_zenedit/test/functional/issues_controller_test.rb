# encoding: utf-8
#
# This file is a part of Redmine ZenEdit (redmine_zenedit) plugin,
# editing enhancement plugin for Redmine
#
# Copyright (C) 2011-2019 RedmineUP
# http://www.redmineup.com/
#
# redmine_zenedit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_zenedit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_zenedit.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class IssuesControllerTest < ActionController::TestCase
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

  fixtures :email_addresses if Redmine::VERSION.to_s >= '3.0'

  def setup
    User.find(1).pref.update_attribute(:no_self_notified, false)
    User.current = User.find(1)
    @request.session[:user_id] = 1
  end

  def create_draft
    Issue.new(subject: 'draft for new issue', project: Project.first).save_draft
  end

  #<LIGHT>
  def test_no_drafts_are_shown
    # Skip this in pro mode
    return
    create_draft
    compatible_request :get, :new
    assert_select('#zen-draft', false)
  end
  #</LIGHT>
  def test_draft_is_shown_on_new
    create_draft
    compatible_request :get, :new, project_id: Project.find(1)
    assert_select('#zen-draft')
  end

  def test_draft_is_not_shown_on_xhr
    create_draft
    compatible_xhr_request :post, :new, project_id: Project.find(1)
    assert_no_match(/<div id=\\\"zen-draft\\\">/, response.body)
  end

  def test_draft_form_corresponding_project_is_shown_on_new
    create_draft
    compatible_request :get, :new, project_id: 1
    assert_select('#zen-draft')
  end

  def test_draft_from_other_project_is_not_shown_on_new
    Issue.new(subject: 'draft for new issue', project: Project.find(2)).save_draft
    compatible_request :get, :new, project_id: 1
    assert_select('#zen-draft', false)
  end

  def test_no_draft_on_new_if_draft_refers_to_other_issue
    issue = Issue.find(2)
    issue.subject = 'draft for issue 2'
    issue.save_draft

    compatible_request :get, :new
    assert_select('#zen-draft', false)
  end

  def test_no_draft_on_new_if_there_are_none
    compatible_request :get, :new
    assert_select('#zen-draft', false)
  end

  def test_draft_is_shown_on_edit
    issue = Issue.find(1)
    issue.subject = 'draft for issue 1'
    issue.save_draft

    compatible_request :get, :edit, id: 1
    assert_select('#zen-draft')
  end

  def test_no_draft_on_edit_if_draft_refers_to_other_issue
    issue = Issue.find(1)
    issue.subject = 'draft for issue 1'
    issue.save_draft

    compatible_request :get, :edit, id: 2
    assert_select('#zen-draft', false)
  end

  def test_draft_is_shown_on_show
    issue = Issue.find(1)
    issue.subject = 'draft for issue 1'
    issue.save_draft

    compatible_request :get, :show, id: 1
    assert_select('#zen-draft')
  end

  def test_no_draft_on_show_if_draft_refers_to_other_issue
    Issue.new(subject: 'draft for new issue').save_draft
    compatible_request :get, :show, id: 1
    assert_select('#zen-draft', false)
  end

  def test_draft_is_removed_on_create
    project = Project.find(1)
    issue = Issue.new(subject: 'hello', project: project)
    issue.save_draft

    assert_difference 'RedmineCrm::ActsAsDraftable::Draft.count', -1 do
      compatible_request :post, :create, issue: issue.attributes
    end
  end

  def test_draft_is_removed_on_update
    issue = Issue.find(2)
    issue.subject = 'changed subject'
    issue.save_draft

    assert_difference 'RedmineCrm::ActsAsDraftable::Draft.count', -1 do
      compatible_request :put, :update, id: 2, issue: { subject: issue.subject }
    end
  end

  def test_post_create_with_mentions
    check_mentions_on :create, ['admin@somenet.foo'], description: 'This is the description'
    check_mentions_on :create, %w(admin@somenet.foo jsmith@somenet.foo), description: '@jsmith hello!'
    check_mentions_on :create, %w(admin@somenet.foo jsmith@somenet.foo), description: '@jsmith, hello!'
    check_mentions_on :create, %w(admin@somenet.foo jsmith@somenet.foo), description: 'Hello @jsmith!'
    check_mentions_on :create, %w(admin@somenet.foo jsmith@somenet.foo), description: 'Hi @jsmith please fix this bug.'
    check_mentions_on :create, %w(admin@somenet.foo jsmith@somenet.foo), description: 'Hi @jsmith, please fix this bug.'
    check_mentions_on :create, %w(admin@somenet.foo jsmith@somenet.foo rhill@somenet.foo), description: '@jsmith @rhill hello!'
    check_mentions_on :create, %w(admin@somenet.foo jsmith@somenet.foo rhill@somenet.foo), description: '@jsmith, @rhill, hello!'

    # Special cases
    check_mentions_on :create, ['admin@somenet.foo'], description: 'Hi, @gmail' # Not exist a user with login gmail
    check_mentions_on :create, ['admin@somenet.foo'], description: 'Emails: jsmith@gmail.com and email@jsmith.com'
    check_mentions_on :create, %w(admin@somenet.foo jsmith@somenet.foo), description: 'Hi @jsmith, you can use email example@rhill.com'
    check_mentions_on :create, ['admin@somenet.foo'], description: '@jsmith@rhill hi @jsmith@rhill jsmith@rhill @@jsmith@ @ hi @, @@'
    check_mentions_on :create, ['admin@somenet.foo'], description: '@jsmith@gmail.com and @jsmith-@rhill_@gmail.com'

    # The mentioned user will not receive a notification, because he can not view private issues
    check_mentions_on :create, ['admin@somenet.foo'], is_private: true, description: '@jsmith, hello!'
  end

  def test_post_update_with_mentions
    check_mentions_on :update, ['jsmith@somenet.foo'], description: 'This is the description', notes: 'This is the note'
    check_mentions_on :update, %w(jsmith@somenet.foo rhill@somenet.foo), description: '@rhill hello!'
    check_mentions_on :update, %w(jsmith@somenet.foo rhill@somenet.foo), description: '@rhill, hello!'
    check_mentions_on :update, %w(jsmith@somenet.foo rhill@somenet.foo), notes: '@rhill hello!'
    check_mentions_on :update, %w(jsmith@somenet.foo rhill@somenet.foo), notes: '@rhill, hello!'
    check_mentions_on :update, %w(jsmith@somenet.foo rhill@somenet.foo dlopper@somenet.foo), description: 'Hi @dlopper!', notes: 'Hi @rhill, please fix this bug.'
    check_mentions_on :update, %w(jsmith@somenet.foo rhill@somenet.foo dlopper@somenet.foo), notes: '@rhill @dlopper hello!'
    check_mentions_on :update, %w(jsmith@somenet.foo rhill@somenet.foo dlopper@somenet.foo), notes: '@rhill, @dlopper, hello!'
    check_mentions_on :update, %w(jsmith@somenet.foo admin@somenet.foo), notes: 'Hi @admin, I found bug.'

    # Special cases
    check_mentions_on :update, ['jsmith@somenet.foo'], notes: 'Hi, @gmail' # Not exist a user with login gmail
    check_mentions_on :update, ['jsmith@somenet.foo'], description: 'Emails: jsmith@gmail.com and email@jsmith.com'
    check_mentions_on :update, %w(admin@somenet.foo jsmith@somenet.foo), description: 'Hi @admin, you can use email example@rhill.com'
    check_mentions_on :update, ['jsmith@somenet.foo'], description: '@jsmith@rhill hi @jsmith@rhill jsmith@rhill @@jsmith@ @ hi @, @@'
    check_mentions_on :update, ['jsmith@somenet.foo'], description: '@jsmith@gmail.com and @jsmith-@rhill_@gmail.com'

    # The mentioned user will not receive a notification, because he can not view private issues
    check_mentions_on :update, ['jsmith@somenet.foo'], is_private: true, notes: '@rhill, hello!'
  end

  private

  def check_mentions_on(action, notified_emails, issue_options)
    ActionMailer::Base.deliveries.clear

    if action == :update
      compatible_request :put, :update, id: 5, issue: issue_options
      assert_redirected_to controller: 'issues', action: 'show', id: 5
    else
      issue_options[:subject] = 'This is a new issue with mentions'
      compatible_request :post, :create, project_id: 3, issue: issue_options

      issue = Issue.where(subject: issue_options[:subject]).order(:id).last
      assert_not_nil issue
      assert_redirected_to controller: 'issues', action: 'show', id: issue
    end

    is_old_redmine = Redmine::VERSION.to_s < '4.0'

    # Redmine-trunk sends mails to every user
    if is_old_redmine
      expected_emails_number = 1
    else
      expected_emails_number = notified_emails.size
    end

    assert_equal expected_emails_number, ActionMailer::Base.deliveries.size, 'An email should have been sent'

    ActionMailer::Base.deliveries.each do |mail|
      assert_not_nil mail
      emails = [mail.bcc, mail.cc].flatten
      if is_old_redmine
        expected_recipients_number = notified_emails.size
      else
        expected_recipients_number = 1
      end
      assert_equal expected_recipients_number, emails.size
      if is_old_redmine
        notified_emails.each { |email| assert emails.include?(email) }
      end
    end
  end
end
