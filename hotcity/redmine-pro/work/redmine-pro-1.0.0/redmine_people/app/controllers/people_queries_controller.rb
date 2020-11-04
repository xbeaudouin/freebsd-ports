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

class PeopleQueriesController < ApplicationController
  before_action :find_query, :except => [:new, :create]

  helper :queries
  include QueriesHelper

  def new
    @query = PeopleQuery.new
    @query.user = User.current

    unless User.current.allowed_people_to?(:manage_public_people_queries) || User.current.admin?
      @query.visibility = PeopleQuery::VISIBILITY_PRIVATE
    end

    @query.build_from_params(params)
  end

  def create
    @query = PeopleQuery.new(params_hash[:query])
    @query.user = User.current

    @query.build_from_params(params_hash)

    unless User.current.allowed_people_to?(:manage_public_people_queries) || User.current.admin?
      @query.visibility = PeopleQuery::VISIBILITY_PRIVATE
    end

    @query.column_names = nil if params_hash[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to url_for(:controller => 'people', :action => 'index', :query_id => @query.id)
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    @query.attributes = params_hash[:query]
    @query.build_from_params(params_hash)

    unless User.current.allowed_people_to?(:manage_public_people_queries) || User.current.admin?
      @query.visibility = PeopleQuery::VISIBILITY_PRIVATE
    end

    @query.column_names = nil if params_hash[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to url_for(:controller => 'people', :action => 'index', :query_id => @query.id)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to url_for(:controller => 'people', :action => 'index', :set_filter => 1)
  end

  private

  def find_query
    @query = PeopleQuery.find(params[:id])
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def params_hash
    @params_hash ||= params.respond_to?(:to_unsafe_hash) ? params.to_unsafe_hash.symbolize_keys : params
  end
end
