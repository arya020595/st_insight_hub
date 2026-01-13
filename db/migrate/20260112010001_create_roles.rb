# frozen_string_literal: true

class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.text :description
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :roles, :name, unique: true
    add_index :roles, :discarded_at
  end
end
