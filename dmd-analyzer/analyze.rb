require 'bitwise'

name = "data/test-dump-1.raw"

data = File.read(name, encoding: 'BINARY')

# Format is https://github.com/neophob/wpc-emu/blob/a8de4bc8bc92689930a36935cb7fb9326c920327/client/scripts/lib/pin2DmdExport.js

puts data[0..128].inspect

## const HEADER = [
##   // RAW as ascii
##   82, 65, 87,
## 
##   // VERSION 1
##   0, 1,
## 
##   // DMD WIDTH in pixels
##   128,
## 
##   // DMD HEIGHT in pixels
##   32,
## 
##   // FRAMES PER IMAGE, always 3 for WPC devices
##   3,
## ];

# Frame documentation https://github.com/neophob/wpc-emu/blob/a8de4bc8bc92689930a36935cb7fb9326c920327/lib/boards/elements/output-dmd-display.js#L4
#  a pixel can have 0%/33%/66%/100% Intensity depending on the display time the last 3 frames
#  input: 512 bytes, one pixel uses 1 bit: 0=off, 1=on
#  output: 4096 bytes, one pixel uses 1 byte: 0=off, 1=33%, 2=66%, 3=100%#

raise "invalid header" unless data[0..2] == "RAW"

# n = 16-bit big endian
# C = 8-bit unsigned
version, height, width, framesPerImage = *data[3..6].unpack("nCCC")

raise "invalid version" unless version == 1
raise "unexpected height/width" unless [height, width] == [128, 32]

headerLength = 8
data = data[headerLength-1..-1]

i = 0
while !data.empty? && i < 1000
  shadedFrame = []

  uptime = data.unpack("Q<")
  puts uptime.inspect

  frameBytes = 128 * 32 / 8

  data = data[4..-1]
  frame = data[0...128*32 / 8 * 3].chars
  puts frame.length

  frames = frame.each_slice(128*32/8).map {|x| Bitwise.new(x.join) }

  (0...128*32).each do |bitIndex|
    intensity = 0
    frames.each do |f|
      intensity += 1 if f.set_at?(bitIndex)
    end
    shadedFrame[bitIndex] = intensity
  end

  formatted = shadedFrame.each_slice(128).map do |row|
    row.each_slice(8).map(&:reverse).flatten.map {|x| [" ", "░", "▒", "▓"].fetch(x) }.join
  end
  puts formatted
  data = data[1536..-1]
  i += 1
end
puts (128 * 32) / 8 * 3
