require 'rspec'
require 'bitwise'
require 'image'

describe Image do
  describe 'to_raw' do
    it 'respects mask' do
      i = Image.new(Bitwise.new("\xFF"), width: 4, height: 2)

      i.mask!(3, 1, 1, 1)
      expect(i.to_raw).to eq(pack_bits "00000001")

      i.mask!(1, 1, 2, 1)
      expect(i.to_raw).to eq(pack_bits "00000110")

      i.mask!(0, 0, 2, 2)
      expect(i.to_raw).to eq(pack_bits "11001100")

      i.mask!(1, 0, 2, 2)
      expect(i.to_raw).to eq(pack_bits "01100110")
    end

    def pack_bits(str)
      # RAW format has bit positions reversed from what you would expect
      [str.reverse].pack("B*")
    end
  end
end
