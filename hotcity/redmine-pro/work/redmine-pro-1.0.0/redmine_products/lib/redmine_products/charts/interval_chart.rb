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

module RedmineProducts
  module Charts
    class IntervalChart
      include Redmine::I18n

      def initialize(query)
        @interval_size = query.interval_size
        @orders = query.orders
        @statement = query.statement
      end

      def data
        @data ||= fill(init_data)
      end

      def currencies
        @currencies ||= @orders.map(&:currency).uniq
      end

      def labels
        data.map do |row|
          date = row['interval'].to_date
          format =
            case @interval_size
            when 'year'
              '%Y'
            when 'quarter'
              "Q#{(date.month - 1) / 3 + 1} %Y"
            when 'month'
              '%b %Y'
            when 'week'
              'w%V'
            when 'day'
              '%Y-%m-%d'
            end

          date.strftime(format)
        end
      end

      def tooltips
        tooltips = data.map { |row| row['interval'].to_s }
        tooltips[0] = (date_from + 1).strftime('%Y-%m-%d')

        unless @interval_size == 'day'
          tooltips << (date_to + 1).strftime('%Y-%m-%d')
          (tooltips.length - 1).times do |i|
            tooltips[i] << " - #{(tooltips[i + 1].to_date - 1).strftime('%Y-%m-%d')}"
          end
          tooltips.pop
        end
        tooltips
      end

      def date_from
        @date_from ||= begin
          date = @statement.match("order_date > '#{db_timestamp_regex}") { |m| Time.zone.parse(m[1]) }
          date ? date + 1 : @orders.first.try(:order_date)
        end
      end

      def date_to
        @date_to ||= @statement.match("order_date <= '#{db_timestamp_regex}") { |m| Time.zone.parse(m[1]) } || @orders.last.try(:order_date)
      end

      def random_color
        "rgba(#{[rand(255), rand(255), rand(255)].join(',')}, 1)"
      end

      private

      def db_timestamp_regex
        /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:.\d*))/
      end

      def fill(data)
        @orders.each do |order|
          interval = data.index { |row| row['interval'] == DateUtils.start_of(@interval_size, order.order_date.localtime) }
          order_params = {
            "#{order.currency}_orders" => 1,
            "#{order.currency}_sales" => order.amount.to_f
          }
          data[interval].merge!(order_params) { |_, old, new| old.to_f + new }
        end
        data
      end

      def init_data
        return [] if @orders.none?
        build_date_intervals([], DateUtils.start_of(@interval_size, date_from))
      end

      def build_date_intervals(intervals, date)
        return intervals if date > date_to.to_date
        intervals << { 'interval' => date }
        build_date_intervals(intervals, DateUtils.next(@interval_size, date))
      end
    end
  end
end
