class Upload < ActiveRecord::Base
  set_table_name :files

  belongs_to :folder, :touch => true, :counter_cache => :size
  belongs_to :user

  has_many :usages, :dependent => :destroy

  validates_presence_of :name, :blank => false
  validates_uniqueness_of :name, :scope => 'folder_id'
  validates_numericality_of :size, :greater_than => 0

  def source=(tempfile)
    raise ArgumentError unless tempfile

    self.temporary_path = tempfile.path
    self.size = tempfile.size
    self.name = tempfile.original_filename
  end

  def extname
    File.extname name
  end

  def absolute_path
    "#{ Rockflu['upload_path'] }/#{ folder_id }/#{ id }"
  end

  protected

    attr_accessor :temporary_path

    # Move tempfile to target path.
    def mv_to_path
      FileUtils.mkdir_p ::File.dirname(absolute_path)
      FileUtils.mv temporary_path, absolute_path
    end
    after_create :mv_to_path

    # Remove file after record has been deleted from database.
    def rm
      FileUtils.rm absolute_path if File.exists? absolute_path
    end
    after_destroy :rm

    # Strips path portion of filename.
    def basenamify
      self.name = File.basename name.gsub('\\\\', '/')
    end
    before_save :basenamify

end