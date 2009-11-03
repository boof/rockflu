# Application-wide functionality used by controllers.
class ApplicationController < ActionController::Base; protected
  helper :all

  def with_current
    @current = Current.new self
    yield
  end
  prepend_around_filter :with_current
  attr_reader :current
  helper_method :current
  public :current
  hide_action :current

  before_filter :authorize # user should be logged in
  
  # Returns the id of the current folder, which is used by the
  # CRUD authorize methods to check the logged in user's permissions.
  def folder_id
    current.folder.id
  end
  helper_method :folder_id
  public :folder_id
  hide_action :folder_id

  def param(key, *default)
    params.fetch key.to_s, *default
  end

  # Check if a folder exists before executing an action.
  # If it doesn't exist: redirect to root and show an error message
  def does_folder_exist
    @folder = Folder.find(params[:id]) if params[:id]
  rescue
    flash.now[:folder_error] = 'Someone else deleted the folder you are using. Your action was cancelled and you have been taken back to the root folder.'
    redirect_to root_path
  end

  # The #authorize method is used as a <tt>before_hook</tt> in most controllers.
  # If the session does not contain a valid user, the method redirects to either
  # AuthenticationController.login or AuthenticationController.create_admin (if no users exist yet).
  def authorize
    @logged_in_user = User.find(session[:user_id])
  rescue
    reset_session
    @logged_in_user = nil
    if User.find(:all).length > 0
      session[:jumpto] = request.parameters
      redirect_to :controller => 'authentication', :action => :login and return false
    else
      redirect_to :controller => 'authentication', :action => :setup and return false
    end
  end

  # If the session does not contain a user with admin privilages (is in the admins
  # group), the method redirects to /folder/list
  def authorize_admin
    redirect_to root_path unless current.user.immortal?
  end

  # Redirect to the Root folder and show an error message
  # if current user cannot create in current folder
  def authorize_creating
    unless current.user.can_create? folder_id
      flash[:folder_error] = 'You don\'t have create permissions for this folder.'
      redirect_to folder_path(folder_id)
    end
  end

  # Redirect to the Root folder and show an error message
  # if current user cannot read in current folder
  def authorize_reading
    unless current.user.can_read? folder_id
      flash[:folder_error] = 'You don\'t have read permissions for this folder.'
      redirect_to root_path
    end
  end

  # Redirect to the Root folder and show an error message
  # if current user cannot update in current folder
  def authorize_updating
    unless current.user.can_update? folder_id
      flash[:folder_error] = 'You don\'t have update permissions for this folder.'
      redirect_to folder_path(folder_id)
    end
  end

  # Check if the logged in user has permission to delete the file
  def authorize_deleting
    unless current.user.can_delete? folder_id
      flash[:folder_error] = 'You don\'t have delete permissions for this folder.'
      redirect_to folder_path(folder_id)
    end
  end
end