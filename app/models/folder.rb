class Folder < ActiveRecord::Base
  acts_as_tree :order => 'name'

  belongs_to :user
  has_many :files, :class_name => 'Rockflu::File', :dependent => :destroy
  has_many :group_permissions, :class_name => 'GroupPermissions', :dependent => :destroy

  validates_uniqueness_of :name, :scope => 'parent_id'
  validates_presence_of :name

  named_scope :root, :conditions => {:root => true}

  attr_accessible :name
  def to_s; name end

  def list(user, folder_order, file_order)
    return unless user.can_read? id
    return children.all(:order => folder_order), files.all(:order => file_order)
  end
  alias_method :ls, :list

  def self.make_root(owner)
    root = new (:name => '/') do |folder|
      folder.user = owner
      folder.root = true
    end
    root.save!

    root
  end

  def absolute_path
    "#{ Rockflu['upload_path'] }/#{ id }"
  end

  protected

    def inherit_permissions
      return if root?

      self.group_permissions = GroupPermissions.find_all_by_folder_id(parent_id).
      map! { |permissions| permissions.clone }
    end
    before_create :inherit_permissions

    def rm_path
      FileUtils.rm_r absolute_path
    end
    after_destroy :rm_path

end
