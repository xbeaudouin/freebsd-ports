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

require 'redmine_zenedit/patches/wiki_formatting_helpers_patch'
require 'redmine_zenedit/helpers/zenedit_helper'

require 'redmine_zenedit/hooks/views_layouts_hook'
require 'redmine_zenedit/hooks/views_issues_hook'

require 'redmine_zenedit/patches/issue_patch'
require 'redmine_zenedit/patches/application_helper_patch'

module RedmineZenedit
  def self.settings() Setting.plugin_redmine_zenedit end

  def self.user_mentions?
    settings['user_mentions'] == '1'

  end

  def self.issue_mentions?
    settings['issue_mentions'] == '1'

  end
end
