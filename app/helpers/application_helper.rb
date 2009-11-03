# Global helper methods for views
module ApplicationHelper
  # Replace 'name' with 'username' in a string
  def name_to_username(string)
    string.try :sub, 'Name', 'Username'
  end

  def chrome_frame_meta
    '<meta http-equiv="X-UA-Compatible" content="chrome=1">'
  end
  def chrome_frame(node = 'chromeFrame', options = {})
    options[:node] = node
    "
      #{ javascript_include_tag 'vendor/CFInstall.min' }
      #{ content_tag :div, :id => node }
      #{ javascript_tag 'CFInstall.check(%s);' % options.to_json }
    "
  end

  # Returns the path to the given folder.
  # Link to self determines wether every part of the path links to itself.
  def path(folder, link_to_self, opts = {})
    if link_to_self
      text = folder.ancestors.
          inject(folder.name) { |text, anc| "#{ anc.name }/#{ text }" }

      link_to h(text), folder_path(folder, opts)
    else
      [ folder, *folder.ancestors ].reverse.
          map { |folder| link_to h(folder.name), folder_path(folder.id, opts) } * ' &middot; '
    end
  end
end