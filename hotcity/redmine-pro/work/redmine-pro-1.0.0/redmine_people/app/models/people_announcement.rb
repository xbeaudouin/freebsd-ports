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

class PeopleAnnouncement < ActiveRecord::Base
  include Redmine::SafeAttributes
  unloadable

  FREQUENCY = %w(once everyday wday mday)
  KIND = %w(notice warning error)
  STATUS = %w(all active)

  acts_as_attachable

  validates_presence_of :description, :end_date

  scope :active, lambda { where('active = ? AND end_date >= ?', true, Date.today) }

  before_save :set_start_date

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'description',
                  'start_date',
                  'end_date',
                  'frequency',
                  'kind',
                  'active'

  def self.for_status(status)
    status = !status.blank? && self::STATUS.include?(status) ? status : 'active'
    send(status)
  end

  def project
    nil
  end

  def attachments_visible?(_user = User.current)
    true
  end

  def attachments_deletable?(usr = User.current)
    usr.allowed_people_to?(:edit_announcement)
  end

  def attachments_editable?(usr = User.current)
    usr.allowed_people_to?(:edit_announcement)
  end

  def start_date
    return created_at.to_date if !self[:start_date] && !created_at.nil?
    self[:start_date]
  end

  def css_class
    "flash #{kind}" if kind
  end

  def self.today(today = Date.today)
    announcements = active.where("(frequency = 'once' AND start_date = ?) OR (frequency = 'everyday') AND (start_date <= ?)", today, today)
    announcements += active.where(:frequency => 'wday').reject { |m|  m.start_date.wday != today.wday }
    announcements += active.where(:frequency => 'mday').reject { |m|  m.start_date.mday != today.mday }
    announcements
  end

  private

  def set_start_date
    self.start_date = Date.today unless start_date
  end
end
