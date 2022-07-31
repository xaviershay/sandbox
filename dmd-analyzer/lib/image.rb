require 'bitwise'

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
    @mask = Bitwise.new("\xFF" * (width*height/8 + 1))
  end

  def clear_mask!
    @mask = Bitwise.new("\xFF" * (width*height/8 + 1))
  end

  def mask!(x, y, w, h)
    @focus = [x, y, w, h]
    @mask = Bitwise.new("\x00" * (width*height/8 + 1))
    (x...x+w).each do |x_coord|
      (y...y+h).each do |y_coord|
        @mask.set_at(y_coord * width + x_coord)
      end
    end
  end

  def fit_to_content
    x_bounds = [width, -1]
    y_bounds = [height, -1]

    (0...width).each do |x|
      (0...height).each do |y|
        bit_index = y * width + x
        if masked_bits.set_at?(bit_index)
          x_bounds[0] = x if x < x_bounds[0]
          x_bounds[1] = x if x > x_bounds[1]
          y_bounds[0] = y if y < y_bounds[0]
          y_bounds[1] = y if y > y_bounds[1]
        end
      end
    end

    new_width = x_bounds[1] - x_bounds[0] + 1
    new_height = y_bounds[1] - y_bounds[0] + 1

    arr = bits.bits.chars.each_slice(width).to_a
    arr = arr[y_bounds[0]..y_bounds[1]].map do |row|
      row[x_bounds[0]..x_bounds[1]]
    end

    Image.new(
      Bitwise.new([arr.join].pack("B*")),
      width: new_width,
      height: new_height
    )
  end

  def ==(other)
    bits.raw == other.bits.raw && width == other.width && height == other.height
  end

  def region_empty?(x, y, w, h)
    region_mask = Bitwise.new("\x00" * (width*height/8))
    (x...x+w).each do |x_coord|
      (y...y+h).each do |y_coord|
        region_mask.set_at(y_coord * width + x_coord)
      end
    end
    (bits & region_mask).cardinality == 0
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
      to_quadrants(unpacked.each_slice(width)).map {|r|
        r.map {|x| quadrant_to_unicode(x) }.join
      }.join("\n")
    when :shaded
      # TODO: This doesn't make sense on Image, should be on Frame
      unpacked.each_slice(128).map do |row|
        row.map {|x| [" ", "░", "▒", "▓"].fetch(x) }.join
      end
    else
      raise "unimplemented style: #{style}"
    end
  end

  def matches_mask?(image)
    (bits & image.mask).raw == image.masked_bits.raw
  end

  attr_reader :width, :height
  protected

  attr_reader :bits, :focus, :mask

  def masked_bits
    bits & mask
  end

  # input = [
  #   [1, 2, 3, 4],
  #   [5, 6, 7, 8],
  #   [9, 10, 11, 12],
  #   [13, 14, 15, 16]
  # ]

  # output = [
  #   [ [1, 2, 5, 6], [3, 4, 7, 8] ],
  #   [ [9, 10, 13, 14], [13, 14, 15, 16] ]
  # ]

  def to_quadrants(input)
    input.each_slice(2).map do |two_rows|
      if two_rows.length == 1
        two_rows << [0] * two_rows[0].length
      end
      a = two_rows.map {|r|
        x = r.each_slice(2).to_a
        if x.last.length == 1
          x.last[1] = 0
        end
        x
      }
      if a.length == 1
        a << [0, 0]
      end
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
end
