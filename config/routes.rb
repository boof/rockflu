ActionController::Routing::Routes.draw do |map|
  map.resources :folders, :except => :index, :member => {
      :feed => :get,
      :edit_permissions => :get,
      :update_permissions => :put
  } do |folders|
    folders.resources :files, :member => {:preview => :get}
  end
  map.root :controller => 'folders', :action => 'show', :id => 1
  map.connect '/progress', :controller => 'files', :action => 'progress'

  # This route helps determine if it's a folder or a file that is
  # being added/remove to/from the clipboard.
  map.connect 'clipboard/:action/:folder_or_file/:id',
              :controller => 'clipboard',
              :requirements => { :action         => /(add|remove)/,
                                 :folder_or_file => /(folder|file)/ }

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
