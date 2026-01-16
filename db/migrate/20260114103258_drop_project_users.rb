class DropProjectUsers < ActiveRecord::Migration[8.1]
  def change
    drop_table :project_users do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
