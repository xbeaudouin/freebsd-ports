class AddIsIncomingToHelpdeskTickets < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :helpdesk_tickets, :is_incoming, :boolean, :default => true
  end
end
