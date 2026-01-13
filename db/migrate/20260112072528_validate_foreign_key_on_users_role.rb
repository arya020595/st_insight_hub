class ValidateForeignKeyOnUsersRole < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :users, :roles
  end
end
