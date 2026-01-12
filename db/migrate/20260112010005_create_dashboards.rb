# frozen_string_literal: true

class CreateDashboards < ActiveRecord::Migration[8.1]
  def change
    create_table :dashboards do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :embed_url, null: false
      t.string :embed_type, null: false, default: 'iframe'
      t.string :status, null: false, default: 'active'
      t.integer :position, default: 0
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :dashboards, :status
    add_index :dashboards, :discarded_at
    add_index :dashboards, %i[project_id position]
  end
end
