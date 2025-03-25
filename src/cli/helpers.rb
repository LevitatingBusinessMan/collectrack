module Enumerable
  def list
    each.with_index(1) do |it, i|
      puts "#{i}. #{it}"
    end
    puts
  end
  def choose
    list
    return if empty?
    #choice = Integer(gets.chomp)
    #self[choice]
    self.first
  end
end
