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
    @folder = Folder.find_by_id params[:id]
    @can_update = current.user.can_update? @folder.id
    @can_delete = current.user.can_delete? @folder.id
    @folders, @files = @folder.list params[:order_by], params[:order]
  end

  def feed
    user = User.find_by_rss_access_key params[:access_key]
    return render(:nothing => true, :status => 401) unless user

    @folder = Folder.find params[:id]

    if not @folder
      render :xml => render_to_string(:no_feed)
    elsif user.can_read? params[:id] or @folder.root?
      @folders, @files = @folder.list
      render :xml => render_to_string(:feed)
    else
      render :nothing => true, :status => 401
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

  def update_permissions
    folder_ids = []

    if params[:recursive]
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
        c,r,u,d = params.
            fetch('permissions', {}).
            fetch("#{ group.id }", {}).
            values_at(*%w[ c r u d ])

        conditions  = {
          :folder_id => folder_ids,
          :group_id => group.id
        }

        if c || r || u || d
          permissions = {
            :can_create => c,
            :can_read   => r,
            :can_update => u,
            :can_delete => d
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
