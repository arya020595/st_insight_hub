class ValidateForeignKeyProjectsCompanies < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :projects, :companies
  end
end
