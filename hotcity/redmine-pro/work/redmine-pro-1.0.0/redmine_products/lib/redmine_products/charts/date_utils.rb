# This file is a part of Redmine Products (redmine_products) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_products is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_products is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_products.  If not, see <http://www.gnu.org/licenses/>.

module RedmineProducts::Charts::DateUtils
  class << self
    def start_of(interval, date)
      send("start_of_#{interval}", date)
    end

    def start_of_year(date)
      Date.new(date.year)
    end

    def start_of_quarter(date)
      first_month_of_quarter =
        case date.month
        when 1..3
          1
        when 4..6
          4
        when 7..9
          7
        else
          10
        end
      Date.new(date.year, first_month_of_quarter)
    end

    def start_of_month(date)
      Date.new(date.year, date.month)
    end

    def start_of_week(date)
      date = date.to_date
      date - date.cwday + 1
    end

    def start_of_day(date)
      Date.new(date.year, date.month, date.day)
    end

    def next(interval, date)
      send("next_#{interval}", date)
    end

    def next_year(date)
      date.next_year
    end

    def next_quarter(date)
      date.next_month(3)
    end

    def next_month(date)
      date.next_month
    end

    def next_week(date)
      date.next_day(7)
    end

    def next_day(date)
      date.next_day
    end
  end
end
