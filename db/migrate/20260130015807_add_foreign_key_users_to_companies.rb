class AddForeignKeyUsersToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :users, :companies, validate: false
  end
end
