class NormalizeColumnnames < ActiveRecord::Migration
  def self.up
    change_table(:folders) { |folders| folders.integer :size, :default => 0 }
    change_table(:files) do |files|
      files.rename :filesize, :size
      files.rename :filename, :name
    end

    Folder.transaction do
      Folder.find(:all).each { |folder|
        updates = { :size => folder.files.count + folder.children.count }
        Folder.update_all updates, :id => folder.id
      }
    end
  end

  def self.down
    change_table(:files) do |files|
      files.rename :name, :filename
      files.rename :size, :filesize
    end
    change_table(:folders) { |folders| folders.remove :size }
  end
end
