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

class PeopleAnnouncementsController < ApplicationController
  unloadable
  helper :attachments
  helper :people_announcements
  helper :people

  before_action :check_setting
  before_action :find_or_create_announcement, :except => [:active, :preview, :index]

  def create
    @note.save_attachments(params[:attachments])
    @note.safe_attributes = params[:people_announcement]
    if @note.save
      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.html { redirect_to people_announcements_path }
        format.js
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.js
      end
    end
  end

  def index
    raise Unauthorized unless User.current.allowed_people_to?(:edit_announcement)
    @announcements = PeopleAnnouncement.for_status(params[:announcements_status])
  end

  def update
    @note.save_attachments(params[:attachments])
    @note.safe_attributes = params[:people_announcement]
    if @note.save
      flash[:notice] = l(:label_announcement_successful_update)
      respond_to do |format|
        format.html { redirect_to people_announcements_path }
      end
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def preview
    note = PeopleAnnouncement.new
    note.safe_attributes = params[:people_announcement]
    render :partial => 'announcement', :layout => false, :locals => { :announcements => [note] }
  end

  def destroy
    if @note.destroy
      flash[:notice] = l(:notice_successful_delete)
      respond_to do |format|
        format.html { redirect_to people_announcements_path }
        format.api { render_api_ok }
      end
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
  end

  private

  def check_setting
    unless RedminePeople.use_announcements?
      redirect_to :controller => 'people_settings', :action => 'index'
      return false
    end
  end

  def find_or_create_announcement
    if params[:action] == 'new' || params[:action] == 'create'
      @note = PeopleAnnouncement.new
    else
      @note = PeopleAnnouncement.find(params[:id])
    end
    raise Unauthorized unless User.current.allowed_people_to?(:edit_announcement)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
