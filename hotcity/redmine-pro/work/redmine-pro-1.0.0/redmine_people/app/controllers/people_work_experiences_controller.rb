# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

class PeopleWorkExperiencesController < ApplicationController
  unloadable

  before_action :set_person
  before_action :check_permissions
  before_action :find_work_experience, :except => [:new, :create]
  before_action :build_new_good_from_params, :only => [:new, :create]

  def new
  end

  def edit
  end

  def create
    @work_experience = PeopleWorkExperience.new
    @work_experience.safe_attributes = params[:work_experience]
    @work_experience.user_id = @person.id
    if @work_experience.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to tabs_person_path(@person, 'work_experience')
        }
      end
    else
      respond_to do |format|
        format.html {
          render :action => 'new'
        }
      end
    end
  end

  def update
    @work_experience.safe_attributes = params[:work_experience]
    if @work_experience.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to tabs_person_path(@person, 'work_experience') }
      end
    else
      respond_to do |format|
        format.html { render 'edit', :project_id => @person, :id => @work_experience }
      end
    end
  end

  def destroy
    @work_experience.destroy
    respond_to do |format|
      format.html { redirect_to tabs_person_path(@person, 'work_experience') }
    end
  end

  private

  def build_new_good_from_params
    @work_experience = PeopleWorkExperience.new
    attrs = (params[:work_experience] || {}).deep_dup
    @work_experience.safe_attributes = attrs
  end

  def find_work_experience
    @work_experience = PeopleWorkExperience.find(params[:id] || params[:ids])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_permissions
    return true if PeopleWorkExperience.edit_work_experience?(@person)
    return true if PeopleWorkExperience.edit_own_work_experience?(@person) && @person.id == User.current.id

    raise Unauthorized
  end
end
