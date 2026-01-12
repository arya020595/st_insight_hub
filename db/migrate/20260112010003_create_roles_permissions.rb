# frozen_string_literal: true

class CreateRolesPermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :roles_permissions do |t|
      t.references :role, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :roles_permissions, %i[role_id permission_id], unique: true
    add_index :roles_permissions, :discarded_at
  end
end
