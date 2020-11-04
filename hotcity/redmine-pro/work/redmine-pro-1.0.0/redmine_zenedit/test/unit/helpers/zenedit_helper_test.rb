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

require File.expand_path('../../../test_helper', __FILE__)

class ZeneditHelperTest < ActionView::TestCase
  include RedmineZenedit::Helper

  def test_find_mentions
    assert_mentions [], ''
    assert_mentions [], 'This is the text without mentions.'

    ['', ' ', ',', ':', ';', '.', '!', '?', '"', "'"].each do |symbol|
      check_around 'a', symbol
      check_around '.a', symbol
      check_around 'admin', symbol
      check_around '@admin', symbol
      check_around 'user-admin', symbol
      check_around 'user_admin', symbol
      check_around 'admin@gmail.com', symbol
      check_around '@admin@gmail.com', symbol
    end

    assert_mentions [], 'email@address.com'
    assert_mentions ['admin'], '@admin, email@gmail.com'
    assert_mentions %w(admin email@gmail.com), '@admin, @email@gmail.com'
    assert_mentions ['user'], 'Hi @user, you can use email example@rhill.com'
    assert_mentions [], 'Emails: jsmith@gmail.com and email@jsmith.com'
    assert_mentions ['admin.@gmail'], 'Hi, @admin.@gmail, hi.'
    assert_mentions ['admin'], 'Hi @admin@ hi @ hi @, @@'
    assert_mentions %w(admin gmail), '@admin @gmail hello!'
    assert_mentions %w(admin gmail), 'Hi @admin, @gmail!'

    assert_mentions ['gmail'], 'Hi, @gmail'
    assert_mentions ['gmail'], 'Hi, @gmail!'
    assert_mentions ['gmail'], 'Hi @gmail!'
    assert_mentions ['gmail'], 'Hi @gmail please fix this bug.'
    assert_mentions %w(admin gmail ivan-061), 'Hi @admin, please test this issue with @gmail. @ivan-061 review the code.'
  end

  private

  def check_around(user, symbol)
    assert_mentions [user], "@#{user}#{symbol}"
    assert_mentions [user], "#{symbol}@#{user}"
    assert_mentions [user], "#{symbol}@#{user}#{symbol}"
  end

  def assert_mentions(exp, text)
    assert_equal exp, find_mentions(text), "Error with text: #{text}"
  end
end
