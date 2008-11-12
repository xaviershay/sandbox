require 'rubygems'
require 'expectations'
require 'ruby2ruby'

K = lambda {|x| lambda { x } }
S = lambda {|x| 
      lambda {|y| 
        lambda {|z| x[z][y[z]] }}}
I = lambda {|x| S[K][K][x] }

def map(char)
  {'K' => K}[char]
end

def eval_l(string)
  string.split('').inject(nil) do |a, v|
    if a.nil?
      map(v)
    else
      a[map(v) || v]
    end
  end
end

Expectations do
  expect 1 do
    K[1][2]
  end

  expect 1 do
    K[1][K]
  end

  expect K do
    K[K][K]
  end

  expect K do
    eval_l('KKK')
  end

  expect '1' do
    eval_l('K1K')
  end

  expect K do
    eval_l('SSKKK')
  end

  expect K[S[S]].to_ruby do
    K[K[K]][S[S]].to_ruby
  end

  expect 1 do
    S[K][K][1]
  end

  expect 1 do
    I[1]
  end
end
