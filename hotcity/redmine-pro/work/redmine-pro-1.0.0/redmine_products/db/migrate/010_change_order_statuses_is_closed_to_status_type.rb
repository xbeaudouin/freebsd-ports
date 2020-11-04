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

class ChangeOrderStatusesIsClosedToStatusType < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def up
    add_column :order_statuses, :status_type, :integer, :null => false, :default => OrderStatus::ORDER_STATUS_TYPE_PROCESSING
    OrderStatus.where(is_closed: true).update_all(status_type: OrderStatus::ORDER_STATUS_TYPE_COMPLETED)
    remove_column :order_statuses, :is_closed
    rename_column :orders, :closed_date, :completed_date
  end

  def down
    add_column :order_statuses, :is_closed, :boolean, :null => true
    rename_column :orders, :completed_date, :closed_date
    remove_column :order_statuses, :status_type
  end

end
