class InitialMigration < ActiveRecord::Migration
  def self.up
    create_table 'folders' do |t|
      t.string :name
      t.integer :user_id, :default => 0
      t.integer :parent_id, :default => 0
      t.boolean :root, :default => false
      t.timestamps
    end
    add_index :folders, :name
    add_index :folders, :user_id
    add_index :folders, :parent_id
    add_index :folders, :root

    create_table 'group_permissions' do |t|
      t.integer :folder_id
      t.integer :group_id
      t.boolean :can_create, :default => false
      t.boolean :can_read, :default => false
      t.boolean :can_update, :default => false
      t.boolean :can_delete, :default => false
    end
    add_index :group_permissions, :folder_id
    add_index :group_permissions, :group_id
    add_index :group_permissions, :can_create
    add_index :group_permissions, :can_read
    add_index :group_permissions, :can_update
    add_index :group_permissions, :can_delete

    create_table 'groups' do |t|
      t.string :name
      t.boolean :administrators, :default => false
    end
    add_index :groups, :name
    add_index :groups, :administrators

    create_table 'groups_users', :id => false do |t|
      t.integer :group_id, :default => 0
      t.integer :user_id, :default => 0
    end
    add_index :groups_users, [:group_id, :user_id]

    create_table 'files' do |t|
      t.string :filename
      t.integer :filesize
      t.integer :folder_id, :default => 0
      t.integer :user_id, :default => 0
      t.timestamps
    end
    add_index :files, :filename
    add_index :files, :folder_id
    add_index :files, :user_id

    create_table 'usages' do |t|
      t.integer :file_id, :default => 0
      t.integer :user_id, :default => 0
      t.timestamp :created_at
    end
    add_index :usages, :file_id
    add_index :usages, :user_id

    create_table 'users' do |t|
      t.string :name
      t.string :email
      t.string :hashed_password
      t.string :password_salt
      t.string :rss_access_key
      t.boolean :immortal, :default => false
    end
    add_index :users, :name
    add_index :users, :email
    add_index :users, :rss_access_key
    add_index :users, :immortal
  end

  def self.down
    drop_table 'folders'
    drop_table 'group_folders'
    drop_table 'groups'
    drop_table 'groups_users'
    drop_table 'files'
    drop_table 'usages'
    drop_table 'users'
  end
end
