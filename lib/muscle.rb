require 'timeout'
class Muscle
  include Enumerable
  
  def initialize
    @threads, @values, @names, @timeouts = {}, {}, [], {}
    yield self
  end
  
  # Use this to declare actions for the muscle to perform
  # 
  # Example:
  #
  # m = Muscle.new do |m|
  #   m.action(:github) do
  #     Net::HTTP.start("github.com"){|h| h.get("/")}
  #   end
  #   m.action(:failblog) do
  #     Net::HTTP.start("failblog.com"){|h| h.get("/")}
  #   end
  # end
  #
  # This will setup a muscle to fetch the page from github.com/ and failblog.com/
  # and make them available in the muscle.  The pages are fetched in the background
  # and will not block until you access the results of the action
  # 
  # options - 
  #   +timeout+ A default timeout of 5 seconds is included.  Set this option for custom timeouts
  # 
  # :api: pulbic
  def action(name = random_name, opts = {}, &block)
    opts[:timeout] ||= 5
    @names << name
    @threads[name] = Thread.new{Timeout::timeout(opts[:timeout], &block)}
    name
  end
  
  # Use this to set a timeout on a given action, or on all actions
  #
  # Example
  #   m.on_timeout(:foo){|name| "#{name} timed out"}
  #   m.on_timeout(:bar){|name| "#{name} timed out"}
  #
  # This example sets a return value for timed out actions and replaces the exception with the
  # results of the block.  If no timeout is set, the original timeout exception is returned.
  #
  # You can also mass declare on_timeout hooks to respond in the same way.
  # The above example would compress to
  #   m.on_timeout(:foo, :bar){|name| "#{name} timed out"}
  #
  # You can also setup a catch all timeout response as a fall back like this
  # 
  #   m.on_timeout{|name| "#{name} timed out"}
  #
  # You can mix and match as many on_timeout handlers as you need.  Named handlers will take precedence
  # over the non-named handlers
  #
  # :api: public
  def on_timeout(*names, &block)
    names = [:any] if names.empty?
    names.each do |n|
      @timeouts[n] = block
    end
  end
  
  # Access the results of the slow action
  # if the action is not yet completed, the process will block until it's done.
  # 
  # :api: public
  def [](name)
    return @values[name] unless @values[name].nil?
    begin
      if @threads[name]
        @values[name] = @threads[name].join.value
        @threads.delete(name)
      end
      @values[name]
    rescue Timeout::Error => e
      if to = (@timeouts[name] || @timeouts[:any])
        to.call(name)
      else
        raise e
      end
    end
  end
  
  # Iterate through the results of each action in declared order.
  # Will block on any uncompleted action
  #
  # :api: public
  def each
    @names.each{|n| yield self[n]}
  end
  
  private
  # provides a random name to an action if one was not specified
  def random_name
    letters ||= ("a".."z").to_a + ("A".."Z").to_a
    (0..15).inject(""){ |out,i| out << letters[rand(letters.length - 1)] }
  end
  
end