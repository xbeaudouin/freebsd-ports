# This file is a part of Redmin Drive (redmine_drive) plugin,
# Filse storage plugin for redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_drive is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_drive is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_drive.  If not, see <http://www.gnu.org/licenses/>.

class IssueDriveFile < ActiveRecord::Base
  belongs_to :issue
  belongs_to :drive_entry

  delegate :filename, :attachment, to: :drive_entry

  validates :issue_id, :drive_entry_id, presence: true

  def visible?(user = User.current)
    issue.visible?(user)
  end

  def increment_downloads(ip, viewer = nil)
    drive_entry.view(ip, viewer)
  end
end
