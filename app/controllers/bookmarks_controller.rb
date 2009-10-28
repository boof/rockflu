class BookmarksController < ApplicationController

  def index
  end

  def show
  end

  def new_bookmark
  end
  def new_folder
  end

  def create
    # get parent node
    # create child node
    @xbel.write xbel_path
  end

  def edit_bookmark
  end
  def edit_folder
  end

  def update
    # get node
    # modify node
    @xbel.write xbel_path
  end

  def destroy
    # delete node
    @xbel.write xbel_path
  end

  protected

    def xbel_path
      Rails.root.join 'db', 'bookmarks.xml'
    end

    def assign_xbel
      # TODO: global, by group, by user
      io = xbel_path.open
      @xbel = XBEL.read_io io
    ensure
      io.close if IO === io
    end
    before_filter :assign_xbel

end
