require 'image'


class Pin2DmdDump
  class Frame < Struct.new(:timestamp, :images)
    def monochrome_image
      images.reduce {|x, y| x.add(y) }
    end
  end

  attr_reader :frames, :width, :height

  def self.from_file(filename)
    data = File.read(filename, encoding: 'BINARY')

    # wpc-emu dump format is defined here, and is the source for the following
    # comments (though it probably copied them from vpinmame, our primary goal
    # here is parsing dumps from wpc-emu):
    #
    #   https://github.com/neophob/wpc-emu/blob/a8de4bc8bc92689930a36935cb7fb9326c920327/client/scripts/lib/pin2DmdExport.js
    #
    # const HEADER = [
    #   // RAW as ascii
    #   82, 65, 87,
    #
    #   // VERSION 1
    #   0, 1,
    #
    #   // DMD WIDTH in pixels
    #   128,
    #
    #   // DMD HEIGHT in pixels
    #   32,
    #
    #   // FRAMES PER IMAGE, always 3 for WPC devices
    #   3,
    # ];
    raise "invalid header" unless data[0..2] == "RAW"

    # n = 16-bit big endian
    # C = 8-bit unsigned
    version, width, height, images_per_frame = *data[3..7].unpack("nC3")

    raise "invalid version" unless version == 1
    raise "unexpected height/width" unless [width, height] == [128, 32]

    headerLength = 8
    data = data[headerLength-1..-1]

    frames = []

    frame_bytes = 128*32/8

    # My test file has left over bytes. First guess is that the dumper simply
    # terminates mid frame whenever you click stop, but this isn't important
    # for my purposes so I haven't investigated.
    while data.length >= frame_bytes * images_per_frame + 4
      # I'll probably come to regret this, but here I've said a frame consists
      # of multiple images, though in wpc-emu what we're calling an Image here
      # is referred to as a frame. (I did this because for our usages that
      # naming makes sense and it's particularly confusing for a user with the
      # original naming.)
      #
      # Intensity is typically calculated by counting how many images a pixel
      # is on for throughout the frame: 0=off, 1=33%, 2=66%, 3=100%
      # We don't care about that here though, and instead generally flatten the
      # image to a monochrome variant.
      #
      # Documentation of frame format is here:
      #
      #     https://github.com/neophob/wpc-emu/blob/a8de4bc8bc92689930a36935cb7fb9326c920327/lib/boards/elements/output-dmd-display.js#L4
      uptime = data.unpack("Q<").first
      data = data[4..-1]
      frame_data = data[0...frame_bytes * images_per_frame]
      data = data[frame_bytes * images_per_frame..-1]

      images = frame_data.chars.each_slice(frame_bytes).map(&:join).map {|x|
        Image.from_raw(x, width: width, height: height)
      }

      frames << Frame.new(uptime, images)
    end

    new(frames)
  end

  def initialize(frames)
    @frames = frames
  end
end
