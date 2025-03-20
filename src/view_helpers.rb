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

class RRDFile; include AHref; end

class Instance
  def graph_imgs_base64 options={}
    graphs(options).map { "<img src=\"data:image;base64,#{Base64.encode64 it}\"/>".html_safe }
  end
  def graph_imgs options={}
    (0..graph_count-1).map { "<img src=\"#{img_link it, options}\" onerror=\"this.style.display='none'\"/>" }
  end
  def img_link n, options={}
    options[:n] = n
    File.join(@plugin.link, self.to_s, "graph") + "?" + URI.encode_www_form(options)
  end
end

class RRDFile
  def graph_img options={}
    "<img src=\"data:image;base64,#{graph(options)}\"/>".html_safe
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
