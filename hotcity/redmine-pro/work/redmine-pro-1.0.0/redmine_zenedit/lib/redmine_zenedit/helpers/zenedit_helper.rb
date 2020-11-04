# encoding: utf-8
#
# This file is a part of Redmine ZenEdit (redmine_zenedit) plugin,
# editing enhancement plugin for Redmine
#
# Copyright (C) 2011-2019 RedmineUP
# http://www.redmineup.com/
#
# redmine_zenedit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_zenedit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_zenedit.  If not, see <http://www.gnu.org/licenses/>.

module RedmineZenedit
  module Helper
    MENTIONS_REGEXP = /\B@[@\w\._-]*\w+/

    def find_mentions(text)
      text.to_s.scan(MENTIONS_REGEXP).map { |mention| mention[1..-1] }.uniq
    end

    def parse_mentions(text)
      mentioned_users = User.where(login: find_mentions(text)).group_by { |user| "@#{user.login}" }
      text.to_s.gsub!(MENTIONS_REGEXP) do |match|
        mentioned_users[match].blank? ? match : link_to_user(mentioned_users[match].first)
      end
    end
  end
end

unless ActionView::Base.included_modules.include?(RedmineZenedit::Helper)
  ActionView::Base.send :include, RedmineZenedit::Helper
end
