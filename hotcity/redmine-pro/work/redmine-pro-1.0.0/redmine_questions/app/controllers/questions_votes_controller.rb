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

class QuestionsVotesController < ApplicationController
  before_action :find_vote_source

  helper :questions

  def create
    if !QuestionsSettings.vote_own? && @vote_source.author == User.current
      render_403
      return false
    end

    voter = User.current.becomes(Principal)
    if !User.current.voted_on?(@vote_source)
      params[:up] ? @vote_source.vote_up(voter) : @vote_source.vote_down(voter)
      flash[:notice] = l(:label_questions_vote_added) unless request.xhr?
    elsif User.current.voted_up_on?(@vote_source) && params[:down] || User.current.voted_down_on?(@vote_source) && params[:up]
      @vote_source.unvote_by(voter)
      flash[:notice] = l(:label_questions_vote_removed) unless request.xhr?
    end

    respond_to do |format|
      format.html { redirect_to_question }
      format.js
    end
  end

  private

  def find_vote_source
    vote_source_type = params[:source_type]
    vote_source_id = params[:source_id]

    klass = Object.const_get(vote_source_type.camelcase)
    @vote_source = klass.find(vote_source_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def redirect_to_question
    question = @vote_source.is_a?(QuestionsAnswer) ? @vote_source.question : @vote_source
    redirect_to question_path(question, :anchor => @vote_source.is_a?(QuestionsAnswer) ? "question_item_#{@vote_source.id}" : '')
  end
end
