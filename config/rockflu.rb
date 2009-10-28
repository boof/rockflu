module Rockflu
  @options = {}
  def self.[](option)
    @options[option]
  end
  def self.[]=(option, value)
    @options[option] = value
  end
end
