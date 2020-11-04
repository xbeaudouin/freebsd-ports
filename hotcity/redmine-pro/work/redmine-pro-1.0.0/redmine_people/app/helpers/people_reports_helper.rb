# encoding: utf-8
#
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

module PeopleReportsHelper
  def people_time_label(seconds)
    hours, minutes = seconds.divmod(60).first.divmod(60)
    "#{hours}<span>#{l(:label_people_hour)}</span> #{minutes}<span>#{l(:label_people_minute)}</span>".html_safe
  end

  def ratio_color_class(ratio)
    return '' if ratio == 0
    ratio < 3 ? 'column_data_yellow' : 'column_data_green'
  end

  def progress_in_percents(value)
    return '0%'.html_safe if value.zero?
    "<span class='caret #{value > 0 ? 'pos' : 'neg'}'></span>#{value}%".html_safe
  end
end
