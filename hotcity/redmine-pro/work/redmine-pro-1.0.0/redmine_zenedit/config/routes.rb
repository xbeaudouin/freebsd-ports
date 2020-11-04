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


get      'zen_draft', to: 'zen_draft#show'
post     'zen_draft', to: 'zen_draft#create'
delete   'zen_draft', to: 'zen_draft#destroy'
get '/zenedit/users_autocomplete', to: 'zenedit#users_autocomplete'
get '/zenedit/issues_autocomplete', to: 'zenedit#issues_autocomplete'

match '/zen_preview', to: 'zen_previews#preview', via: [:get, :post, :put, :patch]
