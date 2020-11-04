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

class ZeneditController < ApplicationController
  RECORDS_LIMIT = 10

  def users_autocomplete
    params[:id].present? ? find_issue : find_project_by_project_id

    users =
      if params[:q].blank? && @project.present?
        @project.users.sorted.like(params[:q]).limit(RECORDS_LIMIT)
      else
        User.active.sorted.like(params[:q]).limit(RECORDS_LIMIT)
      end

    render json: users.reject { |u| u.login.empty? }.map { |u| { value: u.login, label: u.name } }
  end

  def issues_autocomplete
    issues = []
    q = (params[:q] || params[:term]).to_s.strip
    scope = Issue.visible

    if q.match(/\A#?(\d+)\z/)
      issues << scope.find_by_id($1.to_i)
    end

    issues += scope.like(q).order("#{Issue.table_name}.id DESC").limit(RECORDS_LIMIT).to_a
    issues.compact!

    render json: format_issues_json(issues)
  end

  private

  def format_issues_json(issues)
    issues.map do |issue|
      {
        label: "#{issue.tracker} ##{issue.id}: #{issue.subject.to_s.truncate(20)}",
        value: issue.id
      }
    end
  end
end
