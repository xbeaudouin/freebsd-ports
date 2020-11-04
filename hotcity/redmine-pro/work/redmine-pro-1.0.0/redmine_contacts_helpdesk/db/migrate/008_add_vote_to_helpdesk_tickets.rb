class AddVoteToHelpdeskTickets < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :helpdesk_tickets, :vote, :integer, :default => nil
    add_column :helpdesk_tickets, :vote_comment, :string
  end
end
