class CreateReportTemplates < (Rails.version < '5.1') ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :report_templates do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.string :description
      t.text :content
      t.references :project
      t.references :author, null: false
      t.timestamps null: false
    end
  end
end
