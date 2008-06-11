class String
  def interpolate(vars)
    vars.inject(self.dup) do |ret, (key, value)|
      ret.gsub("%(#{key})", value.to_s)
    end
  end
end

puts "%s %s" % [1, 2]
puts "%(a) %(b) %(a)".interpolate(:a => 1, :b => 2)
