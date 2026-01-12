# frozen_string_literal: true

class AddRoleToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Add the reference without foreign key first (for strong_migrations)
    add_reference :users, :role, index: { algorithm: :concurrently }
    add_column :users, :name, :string
    add_column :users, :discarded_at, :datetime

    add_index :users, :discarded_at, algorithm: :concurrently
  end
end
