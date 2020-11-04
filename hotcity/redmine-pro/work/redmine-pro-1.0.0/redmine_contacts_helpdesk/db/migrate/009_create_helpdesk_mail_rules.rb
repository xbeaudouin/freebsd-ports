class CreateHelpdeskMailRules < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :helpdesk_mail_rules do |t|
      t.integer :mail_type
      t.text :conditions
      t.text :actions
      t.integer :user_id, null: false
    end
  end
end
