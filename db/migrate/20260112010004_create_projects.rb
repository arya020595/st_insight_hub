# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.string :status, null: false, default: 'active'
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :projects, :code, unique: true
    add_index :projects, :status
    add_index :projects, :discarded_at
  end
end
