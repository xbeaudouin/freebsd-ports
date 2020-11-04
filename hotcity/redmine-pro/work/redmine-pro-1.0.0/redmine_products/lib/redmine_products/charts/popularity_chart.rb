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
    class PopularityChart
      include Redmine::I18n

      def initialize(query)
        @orders = query.orders
        @orders.joins_values = @orders.includes_values
        @orders.includes_values = []
      end

      def data
        @data ||= top_ten + other
      end

      def labels
        data.map { |row| row['label'] }
      end

      def colors
        data.map { "rgba(#{[rand(255), rand(255), rand(255)].join(',')}, 1)" }
      end

      private

      def top_ten
        sum.first(10).map { |row| { 'label' => row['label'], 'quantity_sum' => row['quantity_sum'] } }
      end

      def other
        quantity_sum = sum.drop(10).inject(0) { |sum, row| sum + row['quantity_sum'].to_f }
        quantity_sum > 0 ? [{ 'label' => l(:label_products_others), 'quantity_sum' => quantity_sum }] : []
      end

      def sum
        @sum ||=
          @orders
            .joins(joins)
            .select("#{grouping_field} AS label, SUM(product_lines.quantity) AS quantity_sum")
            .group(grouping_field)
            .reorder('quantity_sum DESC')
            .to_a
      end

      def joins
        []
      end
    end
  end
end
