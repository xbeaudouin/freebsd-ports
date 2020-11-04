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

require_dependency 'query'

module RedmineProducts
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          self.operators_by_filter_type[:product_list] = self.operators_by_filter_type[:list]

          alias_method :available_filters_without_products, :available_filters
          alias_method :available_filters, :available_filters_with_products
          base.add_available_column(QueryColumn.new(:products, caption: :label_product_plural))
        end
      end

      module InstanceMethods
        def sql_for_products_field(field, operator, value)
          compare = operator == '=' ? 'IN' : 'NOT IN'
          products_select = "SELECT #{ProductsIssue.table_name}.issue_id FROM #{ProductsIssue.table_name}
              WHERE #{ProductsIssue.table_name}.product_id IN (#{value.join(',')})"

          "(#{Issue.table_name}.id #{compare} (#{products_select}))"
        end

        def available_filters_with_products
          if can_add_products_filter?
            if !available_filters_without_products.key?('products') && User.current.allowed_to?(:view_contacts, project, global: true)
              add_available_filter 'products', type: :product_list, name: l(:label_product_plural), values: Product.visible.first(500).map { |p| [p.name, p.id.to_s] }
            end
          else
            available_filters_without_products
          end
          @available_filters
        end

        private

        def can_add_products_filter?
          EnabledModule.where(name: 'products').any? &&
            @available_filters.blank? &&
            User.current.allowed_to?(:view_products, nil, global: true)
        end
      end
    end
  end
end

if Redmine::VERSION.to_s > '2.3.0'
  unless IssueQuery.included_modules.include?(RedmineProducts::Patches::IssueQueryPatch)
    IssueQuery.send(:include, RedmineProducts::Patches::IssueQueryPatch)
  end
else
  unless Query.included_modules.include?(RedmineProducts::Patches::IssueQueryPatch)
    Query.send(:include, RedmineProducts::Patches::IssueQueryPatch)
  end
end
