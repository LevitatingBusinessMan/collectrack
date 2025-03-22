require_relative "config.rex"
require_relative "config.tab"

class Option
  attr_reader :identifier, :arguments
  def initialize identifier, arguments
    @identifier = identifier
    @arguments = arguments
  end

  def to_s
    "#{@identifier} #{@arguments.join(", ")}"
  end

end

class Block
  attr_reader :identifier, :statements, :arguments
  def initialize identifier, arguments, statements
    @identifier = identifier
    @arguments = arguments
    @statements = statements
  end
end
