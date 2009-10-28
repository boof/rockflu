Current = Struct.new :controller do

  def folder_id
    case "#{ params[:controller].pluralize }/#{ params[:action] }"
        when 'folders/show', 'folders/new', 'folders/create', 'folders/edit_permissions', 'folders/update_permissions', 'folders/feed', 'files/validate_filename', 'folders/edit', 'folders/update', 'folders/destroy'
          params[:id] || 1
        when 'files/create', 'files/new', 'files/show', 'files/edit', 'files/update', 'files/destroy', 'files/preview'
          params[:folder_id] || 1
        end
  end
  def folder
    @folder ||= Folder.find folder_id
  end

  def user
    @user ||= controller.instance_variable_get :@logged_in_user
  end

  def file
    @file ||= controller.instance_variable_get :@file
  end

  protected

    def params
      @params ||= controller.send :params
    end

end
