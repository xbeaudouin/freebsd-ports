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

class ZenDraftControllerTest < ActionController::TestCase
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

  def setup
    User.current = User.find(1)
    @request.session[:user_id] = 1
  end

  #<LIGHT>
  def test_draft_is_not_saved
    # Skip in pro mode
    return
    # We won't get ActionNotFound because in light mode controller
    # does not exist
    assert_raise RuntimeError do
      compatible_xhr_request :post, :create, issue: { subject: 'hello' }
    end
  end
  #</LIGHT>
  def test_draft_is_saved
    assert_difference 'RedmineCrm::ActsAsDraftable::Draft.count' do
      compatible_xhr_request :post, :create, issue: { subject: 'hello' }
    end
  end

  def test_draft_with_redundant_params_is_saved
    assert_difference 'RedmineCrm::ActsAsDraftable::Draft.count' do
      compatible_xhr_request :post, :create, issue: { subject: 'hello', redundant: 'redundant param' }
    end
  end

  def test_draft_from_other_project_is_saved_too
    Issue.new(subject: 'subject1', project: Project.find(1)).save_draft

    assert_difference 'RedmineCrm::ActsAsDraftable::Draft.count' do
      compatible_xhr_request(
        :post,
        :create,
        issue: { subject: 'subject2', project_id: 2 }
      )
    end
  end

  def test_draft_from_same_project_updates_existing
    Issue.new(subject: 'subject1', project: Project.find(1)).save_draft
    assert_no_difference 'RedmineCrm::ActsAsDraftable::Draft.count' do
      compatible_xhr_request(
        :post,
        :create,
        issue: { subject: 'subject2', project_id: 1 }
      )
    end
  end

  def test_draft_with_redundant_params_is_updated
    Issue.new(subject: 'original', project: Project.find(1)).save_draft
    compatible_xhr_request :post, :create, issue: { subject: 'updated', project_id: 1, redundant: 'redundant param' }
    issue = Issue.drafts(User.current).last.restore
    assert_equal 'updated', issue.subject
  end

  def test_subject_is_updated
    Issue.new(subject: 'original', project: Project.find(1)).save_draft
    compatible_xhr_request :post, :create, issue: { subject: 'updated', project_id: 1 }
    issue = Issue.drafts(User.current).last.restore
    assert_equal 'updated', issue.subject
  end

  def test_description_is_updated
    Issue.new(description: 'original', project: Project.find(1)).save_draft
    compatible_xhr_request :post, :create, issue: { description: 'updated', project_id: 1 }
    issue = Issue.drafts(User.current).last.restore
    assert_equal 'updated', issue.description
  end

  def test_comment_is_added
    Issue.new.save_draft
    compatible_xhr_request :post, :create, issue: { notes: 'comment' }
    issue = Issue.drafts(User.current).last.restore
    assert_equal 'comment', issue.notes
  end

  def test_comment_is_added_to_persisted_issue
    compatible_xhr_request :post, :create, issue: { id: 1, notes: 'comment' }
    issue = Issue.drafts(User.current).last.restore
    assert_equal 'comment', issue.notes
  end

  def test_comment_is_updated
    issue = Issue.new
    issue.init_journal(User.current)
    issue.notes = 'comment'
    issue.save_draft

    compatible_xhr_request :post, :create, issue: { notes: 'new comment' }
    restored_issue = Issue.drafts(User.current).last.restore
    assert_equal 'new comment', restored_issue.notes
  end

  def test_new_draft_is_saved_for_other_target_id_without_project
    issue = Issue.find(1)
    issue.subject = 'subject1'
    issue.save_draft

    assert_difference 'RedmineCrm::ActsAsDraftable::Draft.count' do
      compatible_xhr_request :post, :create, issue: { id: 2, subject: 'subject2' }
    end
  end

  def test_draft_is_destroyed_for_persisted_issue
    issue = Issue.find(2)
    issue.subject = 'changed subject'
    issue.save_draft

    assert_difference 'RedmineCrm::ActsAsDraftable::Draft.count', -1 do
      compatible_xhr_request :delete, :destroy, issue: { id: 2 }
    end
  end

  def test_draft_is_destroyed_for_new_issue
    project = Project.find(2)
    issue = Issue.new(project: project)
    issue.save_draft

    assert_difference 'RedmineCrm::ActsAsDraftable::Draft.count', -1 do
      compatible_xhr_request :delete, :destroy, issue: { project_id: project.id }
    end
  end

  def test_subject_is_returned
    project = Project.find(1)
    Issue.new(subject: 'subject', project: project).save_draft
    compatible_xhr_request :get, :show, issue: { project_id: project.id }
    assert_equal 'subject', JSON.parse(@response.body)['subject']
  end

  def test_description_is_returned
    project = Project.find(1)
    Issue.new(description: 'description', project: project).save_draft
    compatible_xhr_request :get, :show, issue: { project_id: project.id }
    assert_equal 'description', JSON.parse(@response.body)['description']
  end

  def test_comment_is_returned
    project = Project.find(3)
    issue = Issue.new(project: project)
    issue.init_journal(User.current)
    issue.notes = 'comment'
    issue.save_draft

    compatible_xhr_request :get, :show, issue: { project_id: project.id }
    assert_equal 'comment', JSON.parse(@response.body)['notes']
  end
end
