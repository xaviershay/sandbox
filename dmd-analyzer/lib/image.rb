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
    masked_bits.raw.chars.map {|y|
      y.unpack("B*").map(&:reverse).pack("B*")
    }.join
  end

  def mask_image
    Image.new(mask, width: width, height: height)
  end

  def initialize(bits, width:, height:)
    @bits = bits
    @width = width
    @height = height
    @focus = [0, 0, width, height]
    @mask = Bitwise.new("\xFF" * (width*height/8))
  end

  def mask!(x, y, w, h)
    @focus = [x, y, w, h]
    @mask = Bitwise.new("\x00" * (width*height/8))
    (x...x+w).each do |x_coord|
      (y...y+h).each do |y_coord|
        @mask.set_at(y_coord * width + x_coord)
      end
    end
  end

  def add(image)
    raise "dimensions don't match" unless image.width == self.width && image.height == self.height
    Image.new(self.bits | image.bits, height: height, width: width)
  end

  def formatted(style: :quadrant)
    unpacked = Array.new(width*height)
    (0...width*height).each do |bit_index|
      unpacked[bit_index] =
          masked_bits.set_at?(bit_index) ? 1 : 0
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

  attr_reader :bits, :width, :height, :focus, :mask

  private

  def masked_bits
    bits & mask
  end
end
