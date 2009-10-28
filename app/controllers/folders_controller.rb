# The folder controller contains the following actions:
# [#show]               shows contents of folder
# [#feed]               authorizes, sets appropriate variables and header for RSS feed
# [#feed_warning]       renders page with explanations/warnings about RSS feed
# [#new]                shows the form for creating a new folder
# [#create]             create a new folder
# [#rename]             show the form for adjusting the folder's name
# [#update]             updates the attributes of a folder
# [#destroy]            delete a folder
# [#update_permissions] save the new rights given by the user
class FoldersController < ApplicationController
  skip_before_filter :authorize, :only => :feed

  before_filter :does_folder_exist, :except => [:show, :feed, :feed_warning]
  before_filter :authorize_creating, :only => [:new, :create]
  before_filter :authorize_reading, :only => :show
  before_filter :authorize_updating, :only => [:edit, :update, :edit_permissions, :update_permissions]
  before_filter :authorize_deleting, :only => :destroy

  # List the files and sub-folders in a folder.
  def show
    # Get the folder
    @folder = Folder.find_by_id params[:id]

    # Set if the user is allowed to update or delete in this folder;
    # these instance variables are used in the view.
    @can_update = current.user.can_update? @folder.id
    @can_delete = current.user.can_delete? @folder.id

    # determine the order in which files are shown
    file_order = 'filename '
    file_order = params[:order_by].sub('name', 'filename') + ' ' if params[:order_by]
    file_order += params[:order] if params[:order]

    # determine the order in which folders are shown
    folder_order = 'name '
    if params[:order_by] and params[:order_by] != 'filesize'
      folder_order = params[:order_by] + ' '
      folder_order += params[:order] if params[:order]
    end

    @folders, @files = @folder.list current.user, folder_order.rstrip, file_order.rstrip
  end

  # Authorizes, sets the appropriate variables and headers.
  # The feed is actually implemented in: app/views/folder/feed.rxml.
  def feed
    # check for valid access key:
    user = User.find_by_rss_access_key params[:access_key]
    @authorized = !user.blank?

    # get the folder
    @folder = Folder.find_by_id params[:id]

    # set appriopriate instance variables,
    # so the feed can be created in folder.rxml
    if @authorized and not @folder.blank?
      if @folder.is_root or user.can_read(@folder.id)
        @folders = @folder.list_subfolders(user, 'name')
        @files = @folder.list_files(user, 'filename')
      else
        @authorized = false
      end
    end

    respond_to do |format|
      format.xml {}
    end
  end

  # Shows the form where a user can enter the name for the a folder.
  # The new folder will be stored in the 'current' folder.
  def new
    @parent = Folder.find params[:parent_id]
    @folder = @parent.children.new
  end

  # Create a new folder with the posted variables from the 'new' view.
  def create
    @parent = Folder.find params[:parent_id]
    @folder = @parent.children.new params[:folder]
    @folder.user = current.user

    if @folder.save
      redirect_to folder_path(@folder)
    else
      render :action => :new
    end
  end


  # Update the folder attributes with the posted variables from the 'rename' view.
  def update
    if current.folder.update_attribute(:name, params[:folder][:name])
      redirect_to folder_path(current.folder.parent)
    else
      render :edit
    end
  end

  # Delete a folder.
  def destroy
    @folder.destroy
    redirect_to folder_path(@folder.parent)
  end

  def edit_permissions
    @groups = Group.find :all, :conditions => ['administrators = ?', false]
    @no_permission = GroupPermissions.new
    @permissions = GroupPermissions.find_all_by_folder_id(folder_id).
        inject({}) { |hash, perms| hash.update perms.group_id => perms }
  end

  # Saved the new permissions given by the user
  def update_permissions
    return unless current.user.administrator?
    folder_ids = []

    if params[:update_recursively][:checked] == 'yes'
      stack = [current.folder]
      until stack.empty?
        folder = stack.pop
        stack.concat folder.children
        folder_ids << folder.id
      end
    else
      folder_ids << current.folder.id
    end

    GroupPermissions.transaction do
      Group.unprivileged.each do |group|
        id_str = group.id.to_s
        can_create  = params[:create_check_box][id_str] == '1'
        can_read    = params[:read_check_box][id_str] == '1'
        can_update  = params[:update_check_box][id_str] == '1'
        can_delete  = params[:delete_check_box][id_str] == '1'
        conditions  = {
          :folder_id => folder_ids,
          :group_id => group.id
        }

        if can_create || can_read || can_update || can_delete
          permissions = {
            :can_create => can_create,
            :can_read   => can_read,
            :can_update => can_update,
            :can_delete => can_delete
          }
          GroupPermissions.update_all permissions, conditions

          existing = GroupPermissions.find :all,
              :select => :folder_id, :conditions => conditions
          missing = folder_ids - existing.map { |perm| perm.folder_id }
          missing.all? { |folder_id|
            attributes = permissions.merge :folder_id => folder_id
            group.permissions.new(attributes).save
          } or raise ActiveRecord::Rollback
        else
          GroupPermissions.delete_all conditions
        end
      end
    end
  ensure
    redirect_to folder_path(folder_id)
  end

end