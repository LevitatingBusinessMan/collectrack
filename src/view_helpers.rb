require 'sinatra'
require 'slim'
require './src/collectd'

class Object
  def html_safe?
    self.to_s.html_safe?
  end
end

class String
  def html_safe?
    @html_safe || false
  end

  def html_safe
    @html_safe = true
    self
  end

end

module AHref
  def a
    "<a href=#{self.link}>#{self}</a>".html_safe
  end
end

class Host; include AHref; end
class Plugin; include AHref; end
class Instance; include AHref; end
