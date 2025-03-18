# for https://github.com/MiniProfiler/rack-mini-profiler/issues/608
class ::Rack::Lint::Wrapper
  alias check_headers_orig check_headers
  def check_headers(headers)
      headers = Rack::Headers.new(headers)
      
      check_headers_orig(headers)
  end
end
