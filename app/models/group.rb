# Groups are used to determine which groups of users have which rights
# on which folders.
class Group < ActiveRecord::Base
  has_many :permissions, :class_name => 'GroupPermissions', :dependent => :destroy

  has_and_belongs_to_many :users

  validates_uniqueness_of :name
  validates_presence_of :name

  def protect_administrators
    not administrators?
  end
  before_destroy :protect_administrators

  named_scope :unprivileged, :conditions => {:administrators => false}
  named_scope :administrators, :conditions => {:administrators => true}

  def self.create_administrators(*founders)
    administrators = Group.administrators.
        new :name => 'Administrators', :users => founders
    administrators.save!

    administrators
  end
end