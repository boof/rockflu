require 'digest/sha1'

# A User is used to validate people trying to log in.
# Users can have downloads, create files and folders
# and belong to a group.
# A user's plain text password is not accessible.
# Therefore passwords are hashed before they are stored.
class User < ActiveRecord::Base
  has_and_belongs_to_many :groups
  def permissions
    GroupPermissions.for_user self
  end
  has_many :usages, :dependent => :destroy
  has_many :files, :class_name => 'Upload', :dependent => :nullify
  has_many :folders, :dependent => :nullify

  attr_accessor :password_required
  attr_reader :password

  named_scope :immortal, :conditions => {:immortal => true}

  # We never allow the hashed password to be set from a form
  attr_accessible :name, :email, :password, :password_confirmation, :password_required

  validates_confirmation_of :password, :if => :password_required
  validates_presence_of :password, :if => :password_required
  validates_uniqueness_of :name, :email
  validates_presence_of :name, :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/

  # Password setter
  def password=(new_password)
    @password = new_password
    unless @password.blank?
      salt = User.random_password(6) # whenever the password is set, a new random salt is set too
      self.password_salt = salt
      self.hashed_password = User.hash_password(@password + salt)
    end
  end

  def self.login(name, password)
    user = User.find_by_name name
    user if user and user.hashed_password == User.hash_password("#{ password }#{ user.password_salt }")
  end

  def self.hash_password(password)
    Digest::SHA1.hexdigest password
  end

  def self.random_password(len)
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    random_password = ''
    1.upto(len) { |i| random_password << chars[rand(chars.size-1)] }

    random_password
  end

  # Creates the admin user (but doesn't save it!)
  def self.new_immortal(attributes)
    raise if immortal.exists?

    User.new attributes do |user|
      user.immortal = true
      user.password_required = true
    end
  end

  # Generates a new password for the user with the given username
  # and/or password and mails the password to the user.
  # Returns an appriopriate error message if the given user does not exists.
  def self.generate_and_mail_new_password(name, email)
    # This is the hash that will be returned
    result = Hash.new

    # Check if the name and/or email are valid
    if not name.blank? and not email.blank? # The user entered both name and email
      user = self.find_by_name_and_email(name, email)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this combination of username and e-mail address'
        return result
      end
    elsif not name.blank? # The user only entered the name
      user = self.find_by_name(name)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this username'
        return result
      end
    elsif not email.blank? # The user only entered an e-mail address
      user = User.find_by_email(email)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this e-mail address'
        return result
      end
    else # The user didn't enter anything
      result['flash'] = 'forgotten_notice'
      result['message'] = 'Please enter a username and/or an e-mail address'
      return result
    end

    # So far, so good...
    # Generate a new password
    new_password = User.random_password(8)
    user.password = new_password

    # Store the new password and try to mail it to the user
    begin
      if PasswordMailer.deliver_forgotten(user.name, user.email, new_password) and user.save
        result['flash'] = 'login_confirmation'
        result['message'] = 'A new password has been e-mailed to ' + user.email
      else
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not create a new password'
      end
    rescue Exception => e
      if e.message.match('getaddrinfo: No address associated with nodename')
        result['flash'] = 'forgotten_notice'
        result['message'] = "The mail server settings in the environment file are incorrect. Check the installation instructions to solve this problem. Your password hasn't changed yet."
      else
        result['flash'] = 'forgotten_notice'
        result['message'] = e.message + ".<br /><br />This means either your e-mail address or Boxroom's configuration for e-mailing is invalid. Please contact the administrator or check the installation instructions. Your password hasn't changed yet."
      end
    end

    # finally return the result
    return result
  end

  # Returns if the user is member of the admins group or not
  def administrator?
    immortal? or groups.find_by_administrators true
  end

  # Use this method to determine if a user is permitted to create in the given folder
  def can_create?(folder_id)
    administrator? or
    permissions.for_create.exists? :folder_id => folder_id
  end

  # Use this method to determine if a user is permitted to read in the given folder
  def can_read?(folder_id)
    administrator? or
    permissions.for_read.exists? :folder_id => folder_id
  end

  def can_update?(folder_id)
    administrator? or
    permissions.for_update.exists? :folder_id => folder_id
  end

  def can_delete?(folder_id)
    administrator? or
    permissions.for_delete.exists? :folder_id => folder_id
  end

  def mortal?
    not immortal?
  end
  before_destroy :mortal?

  protected

    def generate_rss_access_key
      self.rss_access_key = User.random_password 36
    end
    before_create :generate_rss_access_key

    def reset_password
      @password = nil
      @password_required = false
    end
    after_save :reset_password

end
