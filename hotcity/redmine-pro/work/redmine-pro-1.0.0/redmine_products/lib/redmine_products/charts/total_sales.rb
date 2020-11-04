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
    class TotalSales < IntervalChart
      def chart_data
        {
          type: 'bar',
          title: l(:label_products_total_sales),
          y_title: l(:label_products_sales),
          labels: labels,
          datasets: datasets,
          currencies: currencies,
          tooltips: tooltips
        }
      end

      def datasets
        currencies.map do |currency|
          {
            label: currency,
            data: dataset(currency),
            backgroundColor: random_color,
            borderColor: 'rgba(102,102,102, 1)',
            borderWidth: 2,
            fill: true
          }
        end
      end

      private

      def dataset(currency)
        data.map { |row| row["#{currency}_sales"].to_f }
      end
    end
  end
end
