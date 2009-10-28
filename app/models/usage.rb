# Usage contains details about which user downloaded
# which file at what time
class Usage < ActiveRecord::Base
  belongs_to :user
  belongs_to :file, :class_name => 'Rockflu::File'
end