class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :status, null: false, default: 'active'
      t.text :description
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :companies, :discarded_at
    add_index :companies, :code, unique: true
  end
end
