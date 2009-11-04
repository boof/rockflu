class AddTypeAndEncoding < ActiveRecord::Migration
  include CMess

  def self.up
    change_table :files do |files|
      files.string :type, :charset
    end

    Upload.transaction do
      Upload.find(:all).each { |upload|
        type = MIME::Types.of(upload.name).first

        upload.type = type
        if type.media_type == 'text'
          file = File.open upload.absolute_path
          upload.charset = GuessEncoding::automatic file
        end

        upload.save
      }
    end
  end

  def self.down
    change_table :files do |files|
      files.remove :type, :charset
    end
  end
end
