module RSpecExtensions
  module At
    def at(time)
      ret = nil
      Timecop.freeze(time) do
        ret = yield(time)
      end
      ret
    end
  end
end
