require 'twitter'

if File.exists?("data.dump")
  data = File.open("data.dump") {|f| Marshal.load(f) }
else  
  t = Twitter::Base.new('username', 'password') 
  data = t.timeline(:friends, :page => :all)
  puts data.inspect
  File.open("data.dump", "w") {|f| Marshal.dump(data, f) }
end

total = 0
data.select {|s| s.text =~ /Week/}.each do |s|
#  puts s.text.gsub(/\n/, '')
  count = s.text[%r{Week ?\d,? Day \d: ((\d+/)+\d+)}i, 1]
  subtotal = count.split('/').collect {|a| a.to_i }.inject(0) {|a, v| a + v}
  puts "%s: %i" % [s.user.name, subtotal]
  total += subtotal
end
# 881269813 is kelly Week 1, Day 1
item = data.detect {|s| s.id == '881269813'}
count = item.text[%r{((\d+/)+\d+)}i, 1]
subtotal = count.split('/').collect {|a| a.to_i }.inject(0) {|a, v| a + v}
puts "%s: %i" % [item.user.name, subtotal]
total += subtotal

puts
puts total
