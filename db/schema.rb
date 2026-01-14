# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_14_022057) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.jsonb "data_after"
    t.jsonb "data_before"
    t.string "ip_address"
    t.jsonb "metadata", default: {}
    t.string "module_name", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.string "user_name"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["module_name"], name: "index_audit_logs_on_module_name"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "embed_type", default: "iframe", null: false
    t.text "embed_url", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.bigint "project_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_dashboards_on_discarded_at"
    t.index ["project_id", "position"], name: "index_dashboards_on_project_id_and_position"
    t.index ["project_id"], name: "index_dashboards_on_project_id"
    t.index ["status"], name: "index_dashboards_on_status"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.string "resource", null: false
    t.string "section"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_permissions_on_code", unique: true
    t.index ["discarded_at"], name: "index_permissions_on_discarded_at"
    t.index ["resource"], name: "index_permissions_on_resource"
  end

  create_table "projects", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.string "icon", default: "bi-folder"
    t.string "name", null: false
    t.boolean "show_in_sidebar", default: true
    t.integer "sidebar_position", default: 0
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_projects_on_code", unique: true
    t.index ["discarded_at"], name: "index_projects_on_discarded_at"
    t.index ["status"], name: "index_projects_on_status"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_roles_on_discarded_at"
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "roles_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_roles_permissions_on_discarded_at"
    t.index ["permission_id"], name: "index_roles_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_roles_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_roles_permissions_on_role_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.datetime "discarded_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.bigint "role_id"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "audit_logs", "users"
  add_foreign_key "dashboards", "projects"
  add_foreign_key "roles_permissions", "permissions"
  add_foreign_key "roles_permissions", "roles"
  add_foreign_key "users", "roles"
end
