class DropProjectsUsers < ActiveRecord::Migration[8.1]
  def change
    safety_assured { drop_table :projects_users }
  end
end
