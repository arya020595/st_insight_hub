class AddForeignKeyProjectsToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :projects, :companies, validate: false
  end
end
