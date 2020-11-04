class AddViewedToJournalMessagesAndTickets < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :journal_messages, :view_id, :string, index: true
    add_column :journal_messages, :viewed_on, :datetime, default: nil

    add_column :helpdesk_tickets, :view_id, :string, index: true
    add_column :helpdesk_tickets, :viewed_on, :datetime, default: nil
  end
end
