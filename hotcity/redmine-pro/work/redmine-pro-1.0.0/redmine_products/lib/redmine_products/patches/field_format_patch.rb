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
  module Patches
    module FieldFormatFormatPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.instance_eval do
          class << self
            alias_method :as_select_without_products, :as_select
            alias_method :as_select, :as_select_with_products
          end
        end
      end

      module ClassMethods
        def as_select_with_products(class_name = nil)
          select_tags = as_select_without_products(class_name)
          select_tags = select_tags.select { |tag| %w(int float date bool string link).include?(tag[1]) } if class_name == 'ProductLine'
          select_tags
        end
      end
    end
  end
end

unless Redmine::FieldFormat.included_modules.include?(RedmineProducts::Patches::FieldFormatFormatPatch)
  Redmine::FieldFormat.send(:include, RedmineProducts::Patches::FieldFormatFormatPatch)
end
