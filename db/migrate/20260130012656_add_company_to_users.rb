class AddCompanyToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :users, :company, null: true, index: { algorithm: :concurrently }
  end
end
