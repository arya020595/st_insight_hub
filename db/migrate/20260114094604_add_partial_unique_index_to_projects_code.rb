class AddPartialUniqueIndexToProjectsCode < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Remove the existing unique index
    remove_index :projects, :code, if_exists: true

    # Add a partial unique index that only applies to non-discarded records
    add_index :projects, :code, unique: true, where: "discarded_at IS NULL", name: "index_projects_on_code_where_not_discarded", algorithm: :concurrently
  end

  def down
    # Remove the partial index
    remove_index :projects, name: "index_projects_on_code_where_not_discarded", if_exists: true, algorithm: :concurrently

    # Restore the original unique index
    add_index :projects, :code, unique: true, algorithm: :concurrently
  end
end
