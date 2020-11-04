# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class DriveEntryTest < ActiveSupport::TestCase
  def setup
  end

  def test_increment_name_cases
    assert_increment_name 'file',             'file (1)'
    assert_increment_name 'file.txt',         'file (1).txt'
    assert_increment_name '.file',            '.file (1)'

    assert_increment_name 'file (1)',         'file (2)'
    assert_increment_name 'file (1).txt',     'file (2).txt'
    assert_increment_name '.file (1)',        '.file (2)'

    assert_increment_name '()',               '() (1)'
    assert_increment_name '().txt',           '() (1).txt'
    assert_increment_name 'file ().txt',      'file () (1).txt'

    assert_increment_name '(1)',              '(1) (1)'
    assert_increment_name '(1).txt',          '(1) (1).txt'

    assert_increment_name '(file)',           '(file) (1)'
    assert_increment_name '(file).txt',       '(file) (1).txt'

    assert_increment_name 'file (0).txt',     'file (0) (1).txt'
    assert_increment_name 'file (text).txt',  'file (text) (1).txt'

    assert_increment_name 'file (1) (1)',     'file (1) (2)'
    assert_increment_name 'file (1) (1).txt', 'file (1) (2).txt'
  end

  private

  def assert_increment_name(before, after)
    drive_entry = DriveEntry.new(name: before)
    drive_entry.increment_name
    assert_equal after, drive_entry.name
  end
end
