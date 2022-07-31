require 'bitwise'

name = "data/test-dump-1.raw"

data = File.read(name, encoding: 'BINARY')

input = [
  [1, 2, 3, 4],
  [5, 6, 7, 8],
  [9, 10, 11, 12],
  [13, 14, 15, 16]
]

output = [
  [ [1, 2, 5, 6], [3, 4, 7, 8] ],
  [ [9, 10, 13, 14], [13, 14, 15, 16] ]
]
def to_quadrants(input)
  input.each_slice(2).map do |two_rows|
    a = two_rows.map {|r| r.each_slice(2).to_a }
    a[0].zip(a[1]).map(&:flatten)
  end
end

def quadrant_to_unicode(quadrant)
  q = quadrant.map {|x| x == 0 ? 0 : 1 }
  {
    [0, 0, 0, 0] => " ",
    [1, 1, 1, 1] => "█",
    [1, 0, 0, 0] => "▘",
    [0, 1, 0, 0] => "▝",
    [0, 0, 1, 0] => "▖",
    [0, 0, 0, 1] => "▗",
    [1, 1, 0, 0] => "▀",
    [0, 0, 1, 1] => "▄",
    [1, 0, 1, 0] => "▌",
    [0, 1, 0, 1] => "▐",
    [1, 0, 0, 1] => "▚",
    [0, 1, 1, 0] => "▞",
    [1, 1, 1, 0] => "▛",
    [1, 1, 0, 1] => "▜",
    [1, 0, 1, 1] => "▙",
    [0, 1, 1, 1] => "▟"
  }.fetch(q)
end

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

class Image
  def self.from_raw(data, width: 128, height: 32)
    # For some reason each byte is flipped, possible something in bitwise
    # library, or maybe just a quirk of output format.
    new(
      Bitwise.new(data.chars.map {|y| y.unpack("B*").map(&:reverse).pack("B*") }.join),
      width: width,
      height: height
    )
  end

  def to_raw
    bits.raw.chars.map {|y| y.unpack("B*").map(&:reverse).pack("B*") }.join
  end

  def initialize(bits, width:, height:)
    @bits = bits
    @width = width
    @height = height
    @focus = [0, 0, width, height]
  end

  def mask!(x, y, w, h)
    @focus = [x, y, w, h]
  end

  def add(image)
    raise "dimensions don't match" unless image.width == self.width && image.height == self.height
    Image.new(self.bits | image.bits, height: height, width: width)
  end

  def formatted(style: :quadrant)
    case style
    when :quadrant
      unpacked = Array.new(width*height).fill(0)
      (0...width*height).each do |bit_index|
        unpacked[bit_index] = 1 if in_focus?(bit_index) && bits.set_at?(bit_index)
      end
      to_quadrants(unpacked.each_slice(128)).map {|r| r.map {|x| quadrant_to_unicode(x) }.join }
    else
      raise "unimplemented style: #{style}"
    end
  end

  protected

  attr_reader :bits, :width, :height, :focus

  private

  def in_focus?(bit_index)
    x = bit_index % width
    y = bit_index / width

    x >= focus[0] && x < focus[0] + focus[2] && y >= focus[1] && y < focus[1] + focus[3]
  end
end

i = 0
skip = 399

while !data.empty? && i < 400
  i += 1
  shaded_frame = []

  uptime = data.unpack("Q<")
  # puts uptime.inspect

  frameBytes = 128 * 32 / 8

  data = data[4..-1]
  frame = data[0...128*32 / 8 * 3]
  data = data[1536..-1]
  next unless i > skip

  frames = frame.chars.each_slice(128*32/8).map(&:join).map {|x|
    Image.from_raw(x).tap do |image|
      unless image.to_raw == x
        p x
        p image.to_raw
        raise "serder doesn't match"
      end
    end
  }

  image = frames.reduce {|x, y| x.add(y) }

  image.mask!(26, 27, 20, 5)
  puts image.formatted
  next

  frames = frame.each_slice(128*32/8).map {|x|
    # For some reason each byte is flipped, possible something in bitwise
    # library, or maybe just a quirk of output format.
    Bitwise.new(x.map {|y| y.unpack("B*").map(&:reverse).pack("B*") }.join)
  }

  (0...128*32).each do |bit_index|
    intensity = 0
    frames.each do |f|
      intensity += 1 if f.set_at?(bit_index)
    end
    shaded_frame[bit_index] = intensity
  end

  formatted = shaded_frame.each_slice(128).map do |row|
    row.map {|x| [" ", "░", "▒", "▓"].fetch(x) }.join
  end

  puts to_quadrants(shaded_frame.each_slice(128)).map {|r| r.map {|x| quadrant_to_unicode(x) }.join }
  # puts formatted

end
