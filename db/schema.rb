# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091028225041) do

  create_table "files", :force => true do |t|
    t.string   "name"
    t.integer  "size"
    t.integer  "folder_id",  :default => 0
    t.integer  "user_id",    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "files", ["folder_id"], :name => "index_files_on_folder_id"
  add_index "files", ["name"], :name => "index_files_on_filename"
  add_index "files", ["user_id"], :name => "index_files_on_user_id"

  create_table "folders", :force => true do |t|
    t.string   "name"
    t.integer  "user_id",    :default => 0
    t.integer  "parent_id",  :default => 0
    t.boolean  "root",       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "size",       :default => 0
  end

  add_index "folders", ["name"], :name => "index_folders_on_name"
  add_index "folders", ["parent_id"], :name => "index_folders_on_parent_id"
  add_index "folders", ["root"], :name => "index_folders_on_root"
  add_index "folders", ["user_id"], :name => "index_folders_on_user_id"

  create_table "group_permissions", :force => true do |t|
    t.integer "folder_id"
    t.integer "group_id"
    t.boolean "can_create", :default => false
    t.boolean "can_read",   :default => false
    t.boolean "can_update", :default => false
    t.boolean "can_delete", :default => false
  end

  add_index "group_permissions", ["can_create"], :name => "index_group_permissions_on_can_create"
  add_index "group_permissions", ["can_delete"], :name => "index_group_permissions_on_can_delete"
  add_index "group_permissions", ["can_read"], :name => "index_group_permissions_on_can_read"
  add_index "group_permissions", ["can_update"], :name => "index_group_permissions_on_can_update"
  add_index "group_permissions", ["folder_id"], :name => "index_group_permissions_on_folder_id"
  add_index "group_permissions", ["group_id"], :name => "index_group_permissions_on_group_id"

  create_table "groups", :force => true do |t|
    t.string  "name"
    t.boolean "administrators", :default => false
  end

  add_index "groups", ["administrators"], :name => "index_groups_on_administrators"
  add_index "groups", ["name"], :name => "index_groups_on_name"

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id", :default => 0
    t.integer "user_id",  :default => 0
  end

  add_index "groups_users", ["group_id", "user_id"], :name => "index_groups_users_on_group_id_and_user_id"

  create_table "usages", :force => true do |t|
    t.integer  "upload_id",  :default => 0
    t.integer  "user_id",    :default => 0
    t.datetime "created_at"
  end

  add_index "usages", ["upload_id"], :name => "index_usages_on_file_id"
  add_index "usages", ["user_id"], :name => "index_usages_on_user_id"

  create_table "users", :force => true do |t|
    t.string  "name"
    t.string  "email"
    t.string  "hashed_password"
    t.string  "password_salt"
    t.string  "rss_access_key"
    t.boolean "immortal",        :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["immortal"], :name => "index_users_on_immortal"
  add_index "users", ["name"], :name => "index_users_on_name"
  add_index "users", ["rss_access_key"], :name => "index_users_on_rss_access_key"

end
