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

  # TODO: remove...
  map.connect ':controller/:action/:id'

  map.connect 'open/*path', :controller => 'convenience', :action => 'open'
end
