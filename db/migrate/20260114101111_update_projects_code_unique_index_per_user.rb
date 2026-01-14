class UpdateProjectsCodeUniqueIndexPerUser < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Remove the existing partial unique index - we'll rely on Rails validation for per-user uniqueness
    remove_index :projects, name: "index_projects_on_code_where_not_discarded", if_exists: true
  end

  def down
    # Restore the global partial unique index
    add_index :projects, :code,
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_projects_on_code_where_not_discarded",
              algorithm: :concurrently
  end
end
