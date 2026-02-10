class RemoveCodeFromCompanies < ActiveRecord::Migration[8.1]
  def change
    remove_index :companies, :code, if_exists: true
    safety_assured { remove_column :companies, :code, :string, null: false }
  end
end
