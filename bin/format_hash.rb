#!/usr/bin/env ruby

# Formats ruby hashes
# a => 1
# ab => 2
# abc => 3
#
# becomes
# a   => 1
# ab  => 2
# abc => 3
#
# http://rhnh.net

lines = []
while line = gets
  lines << line
end

indent = lines.first.index(/[^\s]/)

# Massage into an array of [key, value]
lines.collect! {|line| 
  line.split('=>').collect {|line| 
    line.gsub(/^\s*/, '').gsub(/\s*$/, '') 
  }
}

max_key_length = lines.collect {|line| line[0].length}.max

# Pad each key with whitespace to match length of longest key
lines.collect! {|line|
  line[0] = "%#{indent}s%-#{max_key_length}s" % ['', line[0]]
  line.join(' => ')
}

print lines.join("\n")
