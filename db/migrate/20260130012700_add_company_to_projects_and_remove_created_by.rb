class AddCompanyToProjectsAndRemoveCreatedBy < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :projects, :company, null: true, index: { algorithm: :concurrently }
    safety_assured { remove_column :projects, :created_by_id, :bigint }
  end
end
