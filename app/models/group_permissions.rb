class GroupPermissions < ActiveRecord::Base
  belongs_to :group
  belongs_to :folder

  named_scope :for_user, proc { |user|
    {
      :conditions => {:group_id => user.group_ids},
      :select     => "DISTINCT group_permissions.*"
    }
  }
  named_scope :for_create, :conditions => {:can_create => true}
  named_scope :for_read, :conditions => {:can_read => true}
  named_scope :for_update, :conditions => {:can_update => true}
  named_scope :for_delete, :conditions => {:can_delete => true}

  def self.allow_crud(folder, group)
    permissions = GroupPermission.new { |permissions|
      permissions.folder     = folder
      permissions.group      = group
      permissions.can_create = true
      permissions.can_read   = true
      permissions.can_update = true
      permissions.can_delete = true
    }
    permissions.save!

    permissions
  end
end