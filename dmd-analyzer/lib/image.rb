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
    bit_index = 0
    bits.raw.chars.map {|y|
      y.unpack("B*").map {|bs|
        bs.chars.map do |b|
          if in_focus?(bit_index)
            b
          else
            "0"
          end.tap {|_| bit_index += 1 }
        end.join
      }.map(&:reverse).pack("B*")
    }.join
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
    unpacked = Array.new(width*height)
    (0...width*height).each do |bit_index|
      unpacked[bit_index] =
          in_focus?(bit_index) && bits.set_at?(bit_index) ? 1 : 0
    end

    case style
    when :quadrant
      to_quadrants(unpacked.each_slice(128)).map {|r|
        r.map {|x| quadrant_to_unicode(x) }.join
      }
    when :shaded
      unpacked.each_slice(128).map do |row|
        row.map {|x| [" ", "░", "▒", "▓"].fetch(x) }.join
      end
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

    x1 = focus[0]
    y1 = focus[1]
    x2 = x1 + focus[2]
    y2 = y1 + focus[3]

    x >= x1 && x < x2 && y >= y1 && y < y2
  end
end
