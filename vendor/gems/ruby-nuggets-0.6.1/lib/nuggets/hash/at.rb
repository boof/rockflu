#--
###############################################################################
#                                                                             #
# A component of ruby-nuggets, some extensions to the Ruby programming        #
# language.                                                                   #
#                                                                             #
# Copyright (C) 2007-2008 Jens Wille                                          #
#                                                                             #
# Authors:                                                                    #
#     Jens Wille <jens.wille@uni-koeln.de>                                    #
#                                                                             #
# ruby-nuggets is free software; you can redistribute it and/or modify it     #
# under the terms of the GNU General Public License as published by the Free  #
# Software Foundation; either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# ruby-nuggets is distributed in the hope that it will be useful, but WITHOUT #
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or       #
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for    #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with ruby-nuggets. If not, see <http://www.gnu.org/licenses/>.              #
#                                                                             #
###############################################################################
#++

require 'nuggets/array/rand'

class Hash

  # call-seq:
  #   hash.at(what) => aHash
  #
  # Returns the key/value pair of _hash_ at key position +what+. Remember that
  # hashes might not have the intended (or expected) order in pre-1.9 Ruby.
  def at(what)
    return {} if empty?

    key = case what
      when Integer
        keys[what]
      else
        block_given? ? keys.send(*what) { |*a| yield(*a) } : keys.send(*what)
    end

    { key => self[key] }
  end

  # call-seq:
  #   hash.first => aHash
  #
  # Returns the "first" key/value pair of _hash_.
  def first
    at(:first)
  end

  # call-seq:
  #   hash.last => aHash
  #
  # Returns the "last" key/value pair of _hash_.
  def last
    at(:last)
  end

  # call-seq:
  #   hash.rand => aHash
  #
  # Returns a random key/value pair of _hash_.
  def rand
    at(:rand)
  end

end

if $0 == __FILE__
  h = { :a => 1, 2 => 3, nil => nil, 'foo' => %w[b a r]}
  p h

  p h.first
  p h.last
  p h.rand

  p h.at(0)
  p h.at(1)
  p h.at(-1)
end
