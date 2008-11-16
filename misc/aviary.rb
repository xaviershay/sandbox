require 'rubygems'
require 'expectations'
require 'ruby2ruby'

alias :L :lambda
K = L{|x|
      L{ x }}
S = L{|x| 
      L{|y| 
        L{|z| x[z][y[z]] }}}
I = L{|x| S[K][K][x] }
M = L{|x| I[x][I[x]]}
B = L{|x|
      L{|y|
        L{|z| S[S[K]][K][x][y][z] }}}
W = L{|x|
      L{|y| S[S][K[I]][x][y] }}
L = L{|x|
      L{|y| S[B][K[M]][x][y] }}
T = L{|x|
      L{|y| B[S[I]][K][x][y] }}      
C = L{|x|
      L{|y|
        L{|z| S[B][K[T]][x][y][z] }}}

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

  expect K[K].to_ruby do
    M[K].to_ruby
  end

  expect S[S].to_ruby do
    M[S].to_ruby
  end

  expect K[S[K]].to_ruby do
    B[K][S][K].to_ruby
  end

  expect W[S][K].to_ruby do
    S[K][K].to_ruby
  end

  expect L[S][K].to_ruby do
    S[K[K]].to_ruby
  end

  expect T[S][K].to_ruby do
    K[S].to_ruby
  end

  expect C[S][K][W].to_ruby do
    S[W][K].to_ruby
  end
end

class Molecule
  def initialize
    @args = []
  end

  def to_s
    label + @args.collect {|x| x.to_s }.join('')
  end

  def [](molecule)
    @args << molecule
    explode!
  end

  def explode!
    if @args.length == num_args
      self.execute.explode!
    else
      self
    end
  end
end

class Sclass < Molecule
  def num_args
    3
  end

  def label
    'S'
  end

  def execute
    x, y, z = *@args
    x[y][x[z]]
  end
end

class Kclass < Molecule
  def num_args
    2
  end

  def label
    'K'
  end

  def execute
    x, y = *@args
    x
  end
end

class Testing 
  def k
    Kclass.new
  end

  def s
    Sclass.new
  end

  def initialize
    puts k.to_s
    puts k[k].to_s
    puts k[k][k].to_s
    puts s.to_s
    puts s[k][k][s].to_s
  end
end

Testing.new
