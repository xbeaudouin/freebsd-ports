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

class ZenDraftController < ApplicationController
  before_action :build_issue_from_params
  before_action :restore_issue, only: :create
  def show
    @issue = draft.try(:restore)
    render json: @issue.attributes.merge(notes: @issue.notes)
  end

  def create
    return unless @issue.save_draft
    render json: { status: 200 }, status: 200
  end

  def destroy
    return unless draft.destroy
    render json: { status: 200 }, status: 200
  end

  private

  def build_issue_from_params
    @issue = Issue.new
    @issue.id = unsafe_params['issue']['id']
    @issue.safe_attributes = (unsafe_params['issue'] || {}).deep_dup
    @issue.project_id = unsafe_params['issue']['project_id']
  end

  def unsafe_params
    if params.respond_to?(:to_unsafe_h)
      params.to_unsafe_h
    else
      params
    end
  end

  def draft
    @draft ||= @issue.last_draft
  end

  def restore_issue
    @issue = from_draft if draft

    if params['issue']['notes']
      @issue.init_journal(User.current)
      @issue.notes = params['issue']['notes']
    else
      @issue.notes = nil
    end
    @issue
  end

  def from_draft
    draft.restore.tap do |from_draft|
      safe_assignment(from_draft)
      from_draft.id = @issue.id
    end
  end

  def safe_assignment(draft_issue)
    assignment_params = (unsafe_params['issue'] || {})
    assignment_params.each do |key, value|
      begin
        draft_issue.send("#{key}=", value)
      rescue
        next
      end
    end    
  end
end
