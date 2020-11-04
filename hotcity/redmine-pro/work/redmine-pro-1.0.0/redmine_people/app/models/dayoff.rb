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

class Dayoff < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :user, class_name: 'Person'
  belongs_to :leave_type

  has_one :information, through: :user
  has_one :manager, through: :information
  has_one :department, through: :information

  validates :user_id, :leave_type_id, :start_date, presence: true
  validates :hours_per_day, numericality: { allow_nil: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 24 }
  validate :check_interval

  after_create :send_create_notification

  delegate :color, to: :leave_type

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'user_id', 'leave_type_id', 'approved', 'start_date', 'end_date', 'hours_per_day', 'notes'

  scope :between, lambda { |from, to|
    condition_sql = <<-SQL.squish
      #{table_name}.start_date >= :from AND #{table_name}.start_date <= :to OR
      :from >= #{table_name}.start_date AND :from <= #{table_name}.end_date
    SQL
    where(condition_sql, from: from.to_datetime, to: to.to_datetime)
  }

  def start_date
    self[:start_date].try(:to_date)
  end

  def end_date
    self[:end_date].try(:to_date)
  end

  def due_date
    end_date || start_date
  end

  def due_date=(date)
    self.end_date = date
  end

  def name
    [user.name, ' - ', leave_type.name].join
  end

  def duration
    if hours_per_day
      if start_date == due_date
        "#{to_int_if_whole(hours_per_day)} #{l(:field_hours_per_day_abbreviation)}"
      else
        "#{to_int_if_whole(hours_per_day)} #{l(:field_hours_per_day_abbreviation)}" +
          " #{l(:label_people_scheduled_for)} #{l('datetime.distance_in_words.x_days', count: number_of_days)}"
      end
    else
      l('datetime.distance_in_words.x_days', count: number_of_days)
    end
  end

  def number_of_days
    start_date ? (due_date - start_date).to_i + 1 : 0
  end

  def is_approved?
    !leave_type.approvable || approved
  end

  def notified_users
    current_user = User.current
    [manager, department.try(:head), user].compact.select do |user|
      current_user.id != user.id
    end.uniq
  end

  def recipients
    notified_users.map(&:mail)
  end

  def email_users
    Redmine::VERSION.to_s < '4.0' ? recipients : notified_users
  end

  def event_title
    "#{leave_type.name} #{duration} - (#{user})"
  end

  def url_options
    { controller: 'dayoffs',
      action: 'index',
      set_filter: 1,
      f: [:user_id],
      op: { user_id: '=' },
      v: { user_id: [user_id] },
      year: start_date.year,
      month: start_date.month }
  end

  private

  def check_interval
    if start_date && end_date && end_date < start_date
      errors.add(:end_date, :greater_than_or_equal_to_start_date)
    end
  end

  def send_create_notification
    DayoffsMailer.deliver_dayoff_create(self)
  end

  def to_int_if_whole(float_number)
    float_number.to_i == float_number ? float_number.to_i : float_number.round(2)
  end
end
