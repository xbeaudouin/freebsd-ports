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

module DayoffsMailerHelper
  include Rails.application.routes.url_helpers
  include RedminePeople::Charts::Helpers::ChartHelper

  def render_attributes(attributes, html = false)
    if html
      li_tags = attributes.map { |attribute| "<li><strong>#{attribute[:name]}</strong>: #{attribute[:value]}</li>" }
      content_tag('ul', li_tags.join("\n").html_safe, class: 'details')
    else
      attributes.map { |attribute| "* #{attribute[:name]}: #{attribute[:value]}" }.join("\n")
    end
  end

  def render_dayoff_attributes(dayoff, html = false)
    attributes = tooltip_dayoff_attributes(dayoff, only_path: false).compact
    render_attributes(attributes, html)
  end
end
