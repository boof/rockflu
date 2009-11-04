class FilesController < ApplicationController
  skip_before_filter :authorize, :only => :progress

  before_filter :does_folder_exist, :only => [:new, :create] # if the folder DOES exist, @folder is set to it
  before_filter :assign_file, :except => [:new, :progress, :create]
  before_filter :authorize_creating, :only => :new
  before_filter :authorize_reading, :only => [:show, :preview]
  before_filter :authorize_updating, :only => [:edit, :update]
  before_filter :authorize_deleting, :only => :destroy

  def show
    usage = current.user.usages.new :file => @file

    headers['Content-Transfer-Encoding'] = @file.encoding

    if usage.save
      send_file @file.absolute_path,
          :type => @file.type_with_charset,
          :filename => @file.name, :disposition => 'inline',
          :x_sendfile => Rockflu['x_sendfile']
    end
  end

  def new
    @file = current.folder.files.new
    render :new_with_progress if Rockflu['upload_progress']
  end

  # http://mongrel.rubyforge.org/docs/upload_progress.html
  def progress
    raise NotImplementedError

    render :update do |page|
      @status = Mongrel::Uploads.check(params[:upload_id])
      page.upload_progress.update(@status[:size], @status[:received]) if @status
    end
  end

  def create
    @file = current.folder.files.new params[:file] do |file|
      file.user = current.user
    end

    if @file.save
      redirect_to folder_path(current.folder)
    else
      render :new
    end
  end

  def edit
  end

  def update
    @file.attributes = { :name => params[:file][:name] }

    if @file.save
      redirect_to folder_path(current.folder)
    else
      render :edit
    end
  end

  def preview
    raise NotImplementedError
  end

  def destroy
    @file.destroy
    redirect_to folder_path(current.folder)
  end

  protected
    def assign_file
      @file = Upload.find params[:id]
    rescue
      flash.now[:folder_error] = 'Someone else may have deleted the file you are using. Your action was cancelled and you have been taken back to the parent folder.'
      redirect_to folder_path(current.folder)
    end
end