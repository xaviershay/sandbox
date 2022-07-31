require 'rspec'
require 'bitwise'
require 'image'

describe Image do
  describe '#fit_to_content!' do
    it 'shrinks along x axis' do
      i = Image.new(Bitwise.new(pack_bits "01010"), width: 5, height: 1)
      i = i.fit_to_content

      expected = Image.new(Bitwise.new(pack_bits "101"), width: 3, height: 1)
      expect(i).to eq(expected)
    end

    it 'shrinks along y axis' do
      i = Image.new(Bitwise.new(pack_bits "01010"), width: 1, height: 5)
      i = i.fit_to_content

      expected = Image.new(Bitwise.new(pack_bits "101"), width: 1, height: 3)
      expect(i).to eq(expected)
    end

    it 'respects mask' do
      i = Image.new(Bitwise.new(pack_bits "11011"), width: 5, height: 1)
      i.mask!(1, 0, 3, 1)
      i = i.fit_to_content

      expected = Image.new(Bitwise.new(pack_bits "101"), width: 3, height: 1)
      expect(i).to eq(expected)
    end
  end

  describe '#to_raw' do
    it 'respects mask' do
      i = Image.new(Bitwise.new("\xFF"), width: 4, height: 2)

      i.mask!(3, 1, 1, 1)
      expect(i.to_raw).to eq(pack_raw_bits "00000001")

      i.mask!(1, 1, 2, 1)
      expect(i.to_raw).to eq(pack_raw_bits "00000110")

      i.mask!(0, 0, 2, 2)
      expect(i.to_raw).to eq(pack_raw_bits "11001100")

      i.mask!(1, 0, 2, 2)
      expect(i.to_raw).to eq(pack_raw_bits "01100110")
    end
  end

  describe '#formatted' do
    it 'uses unicode block elements' do
      i = Image.new(Bitwise.new(pack_bits "1000"), width: 2, height: 2)
      expect(i.formatted).to eq("▘")
    end

    it 'handles odd sized images' do
      i = Image.new(Bitwise.new(pack_bits "1"), width: 1, height: 1)
      expect(i.formatted).to eq("▘")

      i = Image.new(Bitwise.new(pack_bits "101"), width: 3, height: 1)
      expect(i.formatted).to eq("▘▘")
    end
  end

  def pack_bits(str)
    [str].pack("B*")
  end

  def pack_raw_bits(str)
    # RAW format has bit positions reversed from what you would expect
    [str.reverse].pack("B*")
  end
end
