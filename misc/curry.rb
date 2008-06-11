module Extensions; end;
module Extensions::Object
  def curry(name, method, *curried_args)
    m = Module.new 
    m.send(:define_method, name, lambda { |*args|
      send method, *curried_args.concat(args)
    })
    self.extend(m)
  end
end

Object.send(:include, Extensions::Object)

string = "Test Yes"
string.curry(:replace_e, :gsub, /e/)
puts string.replace_e("a")

module Another
  def test_method2
    puts "aaaa"
  end
end

m = Module.new 
m.send(:define_method, :test_method, lambda { puts "aaa"})
string.extend(m)
string.test_method
