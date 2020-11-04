# encoding: utf-8
#
# This file is a part of Redmine Q&A (redmine_questions) plugin,
# Q&A plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_questions is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_questions is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_questions.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class QuestionsVotesControllerTest < ActionController::TestCase
  fixtures :users,
           :projects,
           :roles,
           :members,
           :member_roles,
           :trackers,
           :enumerations,
           :projects_trackers,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :workflows,
           :questions,
           :questions_answers,
           :questions_sections

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineQuestions::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_questions).directory + '/test/fixtures/', [:questions, :questions_answers, :questions_sections])

  def setup
    RedmineQuestions::TestCase.prepare
    @controller = QuestionsVotesController.new
    @project = projects(:projects_001)
    @comment = Comment.new(:comments => 'Text', :author => users(:users_001))
    questions(:question_001).comments << @comment
    User.current = nil
  end

  def test_question_upvote
    @request.session[:user_id] = 2
    assert_difference 'RedmineCrm::ActsAsVotable::Vote.count', 1 do
      compatible_request :post, :create, :source_type => 'question', :source_id => questions(:question_001), :up => 'true'
    end
    assert_redirected_to :controller => 'questions', :action => 'show', :id => questions(:question_001), :anchor => ''
  end

  def test_answer_upvote
    @request.session[:user_id] = 1
    assert_difference 'RedmineCrm::ActsAsVotable::Vote.count', 1 do
      compatible_request :post, :create, :source_type => 'questions_answer', :source_id => questions_answers(:answer_001), :up => 'true'
    end
    assert_redirected_to :controller => 'questions', :action => 'show', :id => questions(:question_001), :anchor => 'question_item_1'
  end

  def test_answer_upvote_xhr
    @request.session[:user_id] = 1
    assert_difference 'RedmineCrm::ActsAsVotable::Vote.count', 1 do
      compatible_xhr_request :post, :create, :source_type => 'questions_answer', :source_id => questions_answers(:answer_001), :up => 'true'
    end
  end

  def test_own_vote_with_permission
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_questions => { 'vote_own' => 1 } do
      assert_difference 'RedmineCrm::ActsAsVotable::Vote.count', 1 do
        compatible_request :post, :create, :source_type => 'question', :source_id => questions(:question_001), :up => 'true'
      end
    end
    assert_redirected_to :controller => 'questions', :action => 'show', :id => questions(:question_001), :anchor => ''
  end

  def test_own_vote_without_permission
    @request.session[:user_id] = 1
    assert_no_difference 'RedmineCrm::ActsAsVotable::Vote.count' do
      compatible_request :post, :create, :source_type => 'question', :source_id => questions(:question_001), :up => 'true'
    end
    assert_response 403
  end
end
