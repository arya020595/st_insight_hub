class AddForeignKeyToUsersRole < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :users, :roles, validate: false
  end
end
