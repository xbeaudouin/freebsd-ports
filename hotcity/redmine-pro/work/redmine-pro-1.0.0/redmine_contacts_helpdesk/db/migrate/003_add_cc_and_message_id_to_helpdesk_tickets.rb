class AddCcAndMessageIdToHelpdeskTickets < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :helpdesk_tickets, :cc_address, :string
    add_column :helpdesk_tickets, :message_id, :string
    add_index :helpdesk_tickets, [:message_id]

    add_column :journal_messages, :message_id, :string
    add_index :journal_messages, [:message_id]
  end
end
