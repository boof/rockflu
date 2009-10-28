class RenameColumnsFileIdToUploadId < ActiveRecord::Migration
  def self.up
    change_table(:usages) { |usages| usages.rename :file_id, :upload_id }
  end

  def self.down
    change_table(:usages) { |usages| usages.rename :upload_id, :file_id }
  end
end
