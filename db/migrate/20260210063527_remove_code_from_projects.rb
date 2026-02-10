class RemoveCodeFromProjects < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :projects, :code, :string, null: false }
  end
end
