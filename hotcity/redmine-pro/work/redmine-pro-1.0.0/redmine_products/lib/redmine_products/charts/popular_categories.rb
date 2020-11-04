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
    class PopularCategories < PopularityChart
      def chart_data
        {
          type: 'pie',
          title: l(:label_products_popular_categories),
          datasets: datasets,
          labels: labels
        }
      end

      def datasets
        [{
          data: dataset,
          backgroundColor: colors
        }]
      end

      private

      def dataset
        @dataset ||= data.map { |row| row['quantity_sum'].to_f }
      end

      def joins
        { lines: [product: :category] }
      end

      def grouping_field
        'product_categories.name'
      end
    end
  end
end
