# This file is a part of Redmine Invoices (redmine_contacts_invoices) plugin,
# invoicing plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# https://www.redmineup.com/
#
# redmine_contacts_invoices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts_invoices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts_invoices.  If not, see <http://www.gnu.org/licenses/>.

class InvoiceTemplate < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name', 'content', 'description'

  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'

  validates_presence_of :name
  validates_length_of :name, :maximum => 255

  scope :visible, lambda { |*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :view_invoices, *args)
    eager_load(:project).where("(#{table_name}.project_id IS NULL OR (#{base}))")
  }

  scope :in_project_and_global, lambda { |project|
    where("#{table_name}.project_id IS NULL OR #{table_name}.project_id = 0 OR #{table_name}.project_id = ?", project)
  }
  scope :live_search, lambda { |q| where("(LOWER(#{table_name}.name) LIKE LOWER(?))", "%#{q}%") }

  # Returns true if the query is visible to +user+ or the current user.
  def visible?(user = User.current)
    (project.nil? || user.allowed_to?(:view_invoices, project))
  end
end
