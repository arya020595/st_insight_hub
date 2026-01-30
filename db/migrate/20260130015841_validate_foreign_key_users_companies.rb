class ValidateForeignKeyUsersCompanies < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :users, :companies
  end
end
