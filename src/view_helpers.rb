require "./src/collectd"

class Object
  def html_safe?
    to_s.html_safe?
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
  def a inner=nil
    "<a href=#{link}>#{inner || self}</a>".html_safe
  end
end

class Host; include AHref; end

class Plugin; include AHref; end

class Instance; include AHref; end

class Instance
  def graph_imgs options={}
    graph(options).map { "<img src=\"data:image;base64,#{it}\"/>".html_safe }
  end
end

class Host
  def load_spans
    load = self.load
    if load
      load.map { "<span id=\"load\">#{sprintf "%.2f", it}</span>" }.join.html_safe
    end
  end
end
