class AddCounterCacheToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :users_count, :integer, default: 0, null: false
    add_column :companies, :projects_count, :integer, default: 0, null: false

    # Reset counter cache for existing records
    reversible do |dir|
      dir.up do
        Company.find_each do |company|
          Company.reset_counters(company.id, :users, :projects)
        end
      end
    end
  end
end
