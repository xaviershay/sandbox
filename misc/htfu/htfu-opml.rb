require 'twitter'

if File.exists?("data-opml.dump")
  data = File.open("data-opml.dump") {|f| Marshal.load(f) }
else  
  t = Twitter::Base.new('username', 'password') 
  data = t.friends
  puts data.inspect
  File.open("data-opml.dump", "w") {|f| Marshal.dump(data, f) }
end

puts "[http://twitter.com/statuses/user_timeline/15717895.atom]"
puts "name = xavier_htfu"
puts 

data.each do |u|
  puts "[http://twitter.com/statuses/user_timeline/" + u.id + ".atom]"
  puts "name = " + u.name
  puts
end
