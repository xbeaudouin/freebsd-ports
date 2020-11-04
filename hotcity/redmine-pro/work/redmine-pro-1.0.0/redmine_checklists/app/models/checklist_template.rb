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

class ChecklistTemplate < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes
  belongs_to :project
  belongs_to :tracker
  belongs_to :user
  belongs_to :category, :class_name => "ChecklistTemplateCategory", :foreign_key => "category_id"

  validates_presence_of :name, :template_items
  validates_length_of :name, :maximum => 255

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name', 'template_items', 'project', 'user', 'category_id', 'is_public', 'is_default', 'tracker_id'

  scope :visible, lambda {|*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :view_checklists, *args)
    user_id = user.logged? ? user.id : 0

    eager_load(:project).where("(#{table_name}.project_id IS NULL OR (#{base})) AND (#{table_name}.is_public = ? OR #{table_name}.user_id = ?)", true, user_id)
  }

  scope :in_project_and_global, lambda {|project|
    where("#{table_name}.project_id IS NULL OR #{table_name}.project_id = 0 OR #{table_name}.project_id = ?", project)
  }

  scope :for_tracker_and_global, lambda { |tracker|
    where("#{table_name}.tracker_id IS NULL OR #{table_name}.tracker_id = 0 OR #{table_name}.tracker_id = ?", tracker)
  }

  scope :for_tracker_id, lambda { |tracker_id| where(:tracker_id => tracker_id) }

  scope :default, lambda { where(:is_default => true) }

  def to_s
    name
  end

  def checklists
    template_items.split("\r\n").map do |subject|
      is_section = subject[0..1] == '--'
      value = is_section ? subject[2..-1] : subject
      Checklist.new(subject: value, is_section: is_section)
    end
  end
end
