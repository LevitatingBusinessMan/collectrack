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

class Host
  def load_spans
    load = self.load
    if load
      load.map { "<span id=\"load\">#{sprintf "%.2f", it}</span>" }.join.html_safe
    end
  end
  def children
    plugins
  end
end

class Plugin
  def children
    instances
  end
end

class Instance
  def graph_imgs_base64 options={}
    graphs(options).map { "<img src=\"data:image;base64,#{Base64.encode64 it.read}\"/>".html_safe }
  end
  def graph_imgs options={}
    (0..graph_count-1).map { "<img src=\"#{img_link(it, options)}\" onerror=\"this.style.display='none'\"/>" }
  end
  def img_link n, options={}
    options[:n] = n
    uri = URI(File.join(@plugin.link, self.to_s, "graph"))
    uri.query = URI.encode_www_form(options)
    uri
  end
  def children
    # change to @files to save a miniscule amount of time
    files
  end
end

class RRDFile
  def graph_imgs_base64 options={}
    "<img src=\"data:image;base64,#{graph(options)}\"/>".html_safe
  end
end

#replace a value in a query
def replace_query key, value, uri=@uri
  uri = URI(uri) if uri.class != URI
  uri = uri.dup if uri.frozen?
  query = URI.decode_www_form(uri.query || '').to_h
  query[key] = value
  uri.query = URI.encode_www_form query
  uri
end

# # merge the queries of URIs
def merge_query a, b=@uri
  a = URI(a) unless a.is_a? URI
  b = URI(b) unless b.is_a? URI
  a_query, b_query = [a,b].map { URI.decode_www_form(it.query || '').to_h }
  a.query = URI.encode_www_form(a_query.merge(b_query)) if b_query.size > 0
  a
end

def link obj, inner=nil, attrs={}
  "<a href=#{merge_query(obj.respond_to?(:link) ? obj.link : obj)} #{"title=\"#{obj.children&.join(", ")}\"" if obj.respond_to?(:children)}>#{inner || obj}</a>".html_safe
end
