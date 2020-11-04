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

class LeaveType < ActiveRecord::Base
  include Redmine::SafeAttributes

  COLORS = {
    green: 'green',
    blue: 'blue',
    turquoise: 'turquoise',
    light_green: 'lightgreen',
    yellow: 'yellow',
    orange: 'orange',
    red: 'red',
    purple: 'purple',
    gray: 'gray'
  }.freeze

  has_many :dayoffs, dependent: (Redmine::VERSION.to_s < '3.0' ? :restrict : :restrict_with_error)

  validates :name, presence: true

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name', 'paid', 'approvable', 'color'

  def to_s; name end
end
