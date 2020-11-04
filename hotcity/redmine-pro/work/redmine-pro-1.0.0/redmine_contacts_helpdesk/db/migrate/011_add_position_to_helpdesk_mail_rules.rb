class AddPositionToHelpdeskMailRules < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :helpdesk_mail_rules, :position, :integer, default: 0
  end
end
