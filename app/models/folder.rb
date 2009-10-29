class Folder < ActiveRecord::Base
  acts_as_tree :order => 'name', :counter_cache => :size, :touch => true

  belongs_to :user
  has_many :files, :class_name => 'Upload', :dependent => :destroy
  has_many :group_permissions, :class_name => 'GroupPermissions', :dependent => :destroy

  validates_uniqueness_of :name, :scope => 'parent_id'
  validates_presence_of :name

  named_scope :root, :conditions => {:root => true}

  attr_accessible :name
  def to_s; name end

  def list(by = 'name', dir = 'ASC')
    by = 'name' unless self.class.column_names.include? by
    dir = 'ASC' unless %w[ ASC DESC ].include? dir
    order = "#{ by } #{ dir }"

    return children.all(:order => order), files.all(:order => order)
  end
  alias_method :ls, :list

  def self.make_root(owner)
    root = new(:name => '/') do |folder|
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

    def rm_r
      FileUtils.rm_r absolute_path if File.directory? absolute_path
    end
    after_destroy :rm_r

end
