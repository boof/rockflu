class Rockflu::File < ActiveRecord::Base
  set_table_name :files

  belongs_to :folder
  belongs_to :user

  has_many :usages, :dependent => :destroy

  validates_presence_of :filename, :blank => false
  validates_uniqueness_of :filename, :scope => 'folder_id'
  validates_numericality_of :filesize, :greater_than => 0

  def source=(tempfile)
    raise ArgumentError unless tempfile

    self.temporary_path = tempfile.path
    self.filesize = tempfile.size
    self.filename = tempfile.original_filename
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
    def rm_path
      FileUtils.rm absolute_path
    end
    after_destroy :rm_path

    # Strips path portion of filename.
    def basenamify
      self.filename = File.basename filename.gsub('\\\\', '/')
    end
    before_save :basenamify

end