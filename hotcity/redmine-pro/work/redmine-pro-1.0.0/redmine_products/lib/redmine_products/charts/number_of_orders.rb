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
    class NumberOfOrders < IntervalChart
      def chart_data
        {
          type: 'bar',
          title: l(:label_products_number_of_orders),
          y_title: l(:label_products_number_of_orders),
          labels: labels,
          datasets: datasets,
          tooltips: tooltips
        }
      end

      def datasets
        [{
          label: l(:label_products_number_of_orders_y_axis),
          data: dataset,
          backgroundColor: random_color,
          borderColor: 'rgba(102, 102, 102, 1)',
          borderWidth: 2,
          fill: true
        }]
      end

      private

      def dataset
        data.map do |row|
          currencies.map { |currency| row["#{currency}_orders"].to_i }.inject(:+)
        end
      end
    end
  end
end
