# The file controller contains the following actions:
# [#download]          downloads a file to the users system
# [#progress]          needed for upload progress
# [#upload]            shows the form for uploading files
# [#do_the_upload]     upload to and create a file in the database
# [#validate_filename] validates file to be uploaded
# [#rename]            show the form for adjusting the name of a file
# [#update]            updates the name of a file
# [#destroy]           delete files
# [#preview]           preview file; possibly with highlighted search words
class FilesController < ApplicationController
  skip_before_filter :authorize, :only => :progress

  before_filter :does_folder_exist, :only => [:new, :create] # if the folder DOES exist, @folder is set to it
  before_filter :assign_file, :except => [:new, :progress, :create, :validate_filename]
  before_filter :authorize_creating, :only => :new
  before_filter :authorize_reading, :only => [:show, :preview]
  before_filter :authorize_updating, :only => [:edit, :update]
  before_filter :authorize_deleting, :only => :destroy

  # The requested file will be downloaded to the user's system.
  # Which user downloaded which file at what time will be logged.
  # (adapted from http://wiki.rubyonrails.com/rails/pages/HowtoUploadFiles)
  def show
    # Log the 'usage' and return the file.
    usage = Usage.new
    usage.download_date_time = Time.now
    usage.user = @logged_in_user
    usage.myfile = @file

    if usage.save
      send_file @file.path,
          :filename => @file.filename,
          :x_sendfile => Rockflu['x_sendfile']
    end
  end

  # Shows upload progress.
  # For details, see http://mongrel.rubyforge.org/docs/upload_progress.html
  def progress
    render :update do |page|
      @status = Mongrel::Uploads.check(params[:upload_id])
      page.upload_progress.update(@status[:size], @status[:received]) if @status
    end
  end

  # Shows the form where a user can select a new file to upload.
  def new
    @file = Myfile.new
    render :template => 'files/new_with_progress' if Rockflu['upload_progress']
  end

  # Upload the file and create a record in the database.
  # The file will be stored in the 'current' folder.
  def create
    @file = current.folder.myfiles.new params[:myfile] do |file|
      file.user = current.user
    end

    if @file.save
      redirect_to folder_path(current.folder)
    else
      render :new
    end
  end

  # Validates a selected file in a file field via an Ajax call
  def validate_filename
    filename = CGI::unescape(request.raw_post).chomp('=')
    filename = Myfile.base_part_of(filename)
    if Myfile.find_by_filename_and_folder_id(filename, folder_id).blank?
      render :text => %(<script type="text/javascript">document.getElementById('submit_upload').disabled=false;\nElement.hide('error');\nElement.hide('spinner');</script>)
    else
      render :text => %(<script type="text/javascript">document.getElementById('error').style.display='block';\nElement.hide('spinner');</script>\nThis file can not be uploaded, because it already exists in this folder.)
    end
  end

  # Show a form with the current name of the file in a text field.
  def edit
  end

  # Update the name of the file with the new data.
  def update
    if @file.update_attributes(:filename => Myfile.base_part_of(params[:myfile][:filename]))
      redirect_to folder_path(current.folder)
    else
      render :edit
    end
  end

  # Preview file; possibly with highlighted search words.
  def preview
    if @file.indexed
      if params[:search].blank? # normal case
        @text = @file.text
      else # if we come from the search results page
        @text = @file.highlight(params[:search], { :field => :text, :excerpt_length => :all, :pre_tag => '[h]', :post_tag => '[/h]' })
      end
    end
  end

  # Delete a file.
  def destroy
    @file.destroy
    redirect_to folder_path(current.folder)
  end

  # These methods are private:
  # [#does_file_exist] Check if a file exists before executing an action
  private
    # Check if a file exists before executing an action.
    # If it doesn't exist: redirect to 'list' and show an error message
    def assign_file
      @file = Myfile.find params[:id]
    rescue
      flash.now[:folder_error] = 'Someone else deleted the file you are using. Your action was cancelled and you have been taken back to the parent folder.'
      redirect_to folder_path(current.folder)
    end
end