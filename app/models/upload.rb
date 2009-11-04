class Upload < ActiveRecord::Base
  set_table_name :files
  self.inheritance_column = false

  # code by Ken Bloom (see Ruby Quiz #136), slightly modified by me
  Tag = Struct.new :title, :artist, :album, :year, :comment, :track, :genre do
    GENRES = %w[ Blues Classic\ Rock Country Dance Disco Funk Grunge Hip-Hop Jazz
                 Metal New\ Age Oldies Other Pop R&B Rap Reggae Rock Techno
                 Industrial Alternative Ska Death\ Metal Pranks Soundtrack
                 Euro-Techno Ambient Trip-Hop Vocal Jazz+Funk Fusion Trance
                 Classical Instrumental Acid House Game Sound\ Clip Gospel Noise
                 AlternRock Bass Soul Punk Space Meditative Instrumental\ Pop
                 Instrumental\ Rock Ethnic Gothic Darkwave Techno-Industrial
                 Electronic Pop-Folk Eurodance Dream Southern\ Rock Comedy Cult
                 Gangsta Top\ 40 Christian\ Rap Pop/Funk Jungle Native\ American
                 Cabaret New\ Wave Psychadelic Rave Showtunes Trailer Lo-Fi Tribal
                 Acid\ Punk Acid\ Jazz Polka Retro Musical Rock\ &\ Roll Hard\ Rock
                 Folk Folk-Rock National\ Folk Swing Fast\ Fusion Bebob Latin
                 Revival Celtic Bluegrass Avantgarde Gothic\ Rock Progressive\ Rock
                 Psychedelic\ Rock Symphonic\ Rock Slow\ Rock Big\ Band Chorus
                 Easy\ Listening Acoustic Humour Speech Chanson Opera Chamber\ Music
                 Sonata Symphony Booty\ Bass Primus Porn\ Groove Satire Slow\ Jam
                 Club Tango Samba Folklore Ballad Power\ Ballad Rhythmic\ Soul
                 Freestyle Duet Punk\ Rock Drum\ Solo A\ capella Euro-House
                 Dance\ Hall ]

    def self.open(path)
      File.open path do |file|
        file.seek -128, IO::SEEK_END
        tag = file.read.unpack 'A3A30A30A30A4A30C1'

        return if tag.first != 'TAG'

        tag[5] = if tag[5][-2] == 0 and tag[5][-1] != 0
          tag[5].unpack('A28A1C1').values_at 0, 2
        else
          [tag[5], nil]
        end

        new(*tag.flatten[1..-1])
      end
    end

    def blank?
      values.to_s == title
    end

    def to_s
      blank?? title :
        [genre, artist, "#{ year } #{ album }", "#{ track } #{ title }"] * ' - '
    end

    def genre
      GENRES[values.last]
    end
  end

  def self.fuzzy_find_all_by_name(name, options = {})
    conditions = ['lower(name) = ?', name.downcase]
    find :all, options.merge(:conditions => conditions)
  end

  belongs_to :folder, :touch => true, :counter_cache => :size
  belongs_to :user

  has_many :usages, :dependent => :destroy

  validates_presence_of :name, :blank => false
  validates_uniqueness_of :name, :scope => 'folder_id'
  validates_numericality_of :size, :greater_than => 0

  def type=(type)
    write_attribute :type, type.to_s
    @type = type
  end
  def type
    @type ||= MIME::Types[read_attribute(:type)].first
  end
  def encoding
    type.encoding
  end
  def type_with_charset
    charset ? "#{ type }; charset=#{ charset}" : type
  end

  def source=(tempfile)
    raise ArgumentError unless tempfile

    self.temporary_path = tempfile.path
    self.size = tempfile.size
    self.name = tempfile.original_filename
    self.type = MIME::Types.of(tempfile.original_filename).first

    type.media_type != 'text' or
    self.charset = CMess::GuessEncoding::automatic(tempfile)
  end

  def id3
    @id3 ||= Tag.open(absolute_path) || Tag.new(name)
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