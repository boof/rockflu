class ConvenienceController < ApplicationController

  def open path = param(:path)
    last, name = path.pop, path.pop

    begin
      uploads = Upload.fuzzy_find_all_by_name last, :include => :folder
      upload = if uploads.length == 1 then uploads.first
      else
        parents = select_parents_by_name_into_hash uploads, name, :folder
        parents.fetch reduce(parents.keys, path)
      end

      open_upload upload
    rescue IndexError
      folders = Folder.fuzzy_find_all_by_name last
      folder = if folders.length == 1 then folders.first
      else
        parents = select_parents_by_name_into_hash folders, name
        parents.fetch reduce(parents.keys, path)
      end

      open_folder folder
    end
  rescue IndexError
    no_such_file_or_directory
  end

  protected

    def no_such_file_or_directory
      flash[:error] = 'No such file or directory'
      redirect_to root_path
    end
    def permission_denied
      flash[:error] = 'Permission denied'
      redirect_to root_path
    end
    def open_folder(folder)
      if current.user.can_read? folder
        redirect_to folder_path(folder)
      else
        permission_denied
      end
    end
    def open_upload(upload, folder = upload.folder)
      if current.user.can_read? folder
        redirect_to folder_file_path(folder, upload)
      else
        permission_denied
      end
    end

    def select_parents_by_name_into_hash(children, name, message = :parent)
      children.inject({}) { |parents, child|
        parent = child.send message
        parent.name.downcase == name.downcase ?
            parents.update(parent => child) :
            parents
      }
    end
    def reduce children, names, index = names.length - 1, name = names[index]
      if index > 0 and children.length > 1
        parents = select_parents_by_name_into_hash children, name
        parents.fetch reduce(parent.keys, names, index - 1)
      elsif children.length == 1
        children.first
      end
    end

end
