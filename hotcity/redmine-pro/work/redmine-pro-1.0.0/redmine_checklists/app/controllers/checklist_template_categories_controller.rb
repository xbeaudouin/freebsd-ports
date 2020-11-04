# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

class ChecklistTemplateCategoriesController < ApplicationController
  unloadable

  before_action :find_category, :only => [:destroy, :update, :edit]

  def create
    @category = ChecklistTemplateCategory.new
    @category.safe_attributes = params[:category]
    if @category.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_list
    else
      render :action => 'new'
    end
  end

  def destroy
    @category.destroy
    redirect_to_list
  rescue
    flash[:error] = l(:label_finance_can_not_delete_category)
    redirect_to_list
  end

  def update
    @category.safe_attributes = params[:category]
    @category.insert_at(@category.position) if @category.position_changed?
    if @category.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_to_list
        end
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.js { head 422 }
      end
    end
  end

private

  def find_category
    @category = ChecklistTemplateCategory.find(params[:id])
  end

  def redirect_to_list
    redirect_to :action =>"plugin", :id => "redmine_checklists", :controller => "settings", :tab => 'checklist_template_categories'
  end
end
