# frozen_string_literal: true

class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :resource, null: false
      t.string :section
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :permissions, :code, unique: true
    add_index :permissions, :resource
    add_index :permissions, :discarded_at
  end
end
