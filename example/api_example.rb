require File.join(File.dirname(__FILE__), "..", "lib", "muscle")
require 'net/http'

@m = Muscle.new do |m|
  m.action(:github) do
    Net::HTTP.start("github.com"){|h| h.get("/")}
  end
  m.action(:google) do
    Net::HTTP.start("google.com"){|h| h.get("/")}
  end
end

# actions are threaded and fetched in the background.  Blocking does not occur until they are accessed

@m[:github] # <-- blocks until the page is loaded