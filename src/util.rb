# also see https://github.com/rubyworks/facets/blob/12326d4767bd109bdf5f9fa3582797bd88c36d30/lib/core/facets/string/interpolate.rb
def evalstr str
  eval "\"#{str}\""
end

class Hash
  def symbolize_keys
    transform_keys { |key| key.to_sym rescue key }
  end
end

class String
  def numeric?
    (Integer(self) rescue false) and true
  end

  def camelize
    split('_').collect(&:capitalize).join
  end
end

class Thread::Queue
  def join
    out = []
    out << pop while not closed?
  end
end
