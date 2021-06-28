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

ActiveRecord::Schema.define(version: 2021_06_28_225426) do

  create_table "projects", force: :cascade do |t|
    t.text "original_id"
    t.text "name"
    t.datetime "due_date"
    t.datetime "start_date"
    t.integer "workspace_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["workspace_id"], name: "index_projects_on_workspace_id"
  end

  create_table "sources", force: :cascade do |t|
    t.text "name"
    t.text "access_token"
    t.text "account_id"
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_sources_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.text "name"
    t.integer "project_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "time_entries", force: :cascade do |t|
    t.integer "duration_seconds"
    t.datetime "started_at"
    t.integer "task_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["task_id"], name: "index_time_entries_on_task_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "email"
    t.text "password_digest"
    t.text "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "workspaces", force: :cascade do |t|
    t.text "original_id"
    t.text "source_name"
    t.integer "source_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["source_id"], name: "index_workspaces_on_source_id"
  end

  add_foreign_key "projects", "workspaces"
  add_foreign_key "sources", "users"
  add_foreign_key "tasks", "projects"
  add_foreign_key "time_entries", "tasks"
  add_foreign_key "workspaces", "sources"
end
