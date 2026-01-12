# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, foreign_key: true
      t.string :user_name
      t.string :module_name, null: false
      t.string :action, null: false
      t.string :auditable_type
      t.bigint :auditable_id
      t.text :summary
      t.jsonb :metadata, default: {}
      t.jsonb :data_before
      t.jsonb :data_after
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :audit_logs, :action
    add_index :audit_logs, :module_name
    add_index :audit_logs, %i[auditable_type auditable_id]
    add_index :audit_logs, :created_at
  end
end
