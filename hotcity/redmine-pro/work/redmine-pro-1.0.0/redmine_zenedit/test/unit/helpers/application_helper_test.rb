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

class ApplicationHelperTest < ActionView::TestCase
  include ERB::Util

  fixtures :users
  def test_textilizable_with_zen_mentions
    link_to_jsmith = link_to_user User.find(2)
    link_to_rhill = link_to_user User.find(4)

    test_cases = {
      'This is the description'                         => 'This is the description',
      '@jsmith hello!'                                  => "#{link_to_jsmith} hello!",
      '@jsmith, hello!'                                 => "#{link_to_jsmith}, hello!",
      'Hello @jsmith!'                                  => "Hello #{link_to_jsmith}!",
      'Hi @jsmith please fix this bug.'                 => "Hi #{link_to_jsmith} please fix this bug.",
      'Hi @jsmith, please fix this bug.'                => "Hi #{link_to_jsmith}, please fix this bug.",
      '@jsmith @rhill hello!'                           => "#{link_to_jsmith} #{link_to_rhill} hello!",
      '@jsmith, @rhill, hello!'                         => "#{link_to_jsmith}, #{link_to_rhill}, hello!",
      'Hi, @gmail'                                      => 'Hi, @gmail', # Not exist a user with login gmail
      'http://foo@www.bar.com'                          => '<a class="external" href="http://foo@www.bar.com">http://foo@www.bar.com</a>',
      'http://foo:bar@www.bar.com'                      => '<a class="external" href="http://foo:bar@www.bar.com">http://foo:bar@www.bar.com</a>',
      'Emails: jsmith@gmail.com and email@jsmith.com'   => 'Emails: <a class="email" href="mailto:jsmith@gmail.com">jsmith@gmail.com</a> and <a class="email" href="mailto:email@jsmith.com">email@jsmith.com</a>',
      'Hi @jsmith, you can use email example@rhill.com' => %(Hi #{link_to_jsmith}, you can use email <a class="email" href="mailto:example@rhill.com">example@rhill.com</a>),
    }

    test_cases.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text), "Error with text: #{text}" }
  end
end
