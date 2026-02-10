class CreateDashboardsUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :dashboards_users, id: false do |t|
      t.references :dashboard, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :dashboards_users, [ :dashboard_id, :user_id ], unique: true
    add_index :dashboards_users, [ :user_id, :dashboard_id ]
  end
end
