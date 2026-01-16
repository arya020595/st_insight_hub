class AddCreatedByToProjects < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :projects, :created_by, index: { algorithm: :concurrently }
  end
end
