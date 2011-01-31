require 'benchmark'
require 'yaml'
require 'json' # gem install json

hash = {
  :name => 'Xavier',
  :age  => 24,
  :likes => ["Climbing", "Computers", "Food"]}

n = 10000

marshal_hash = Marshal.dump(hash)
yaml_hash = YAML.dump(hash)
json_hash = JSON.dump(hash)

Benchmark.bm do |b|
  b.report("Marshal serialize") do
    n.times { Marshal.dump(hash) }
  end
  b.report("Marshal deserialize") do
    n.times { Marshal.load(marshal_hash) }
  end
  b.report("JSON serialize") do
    n.times { JSON.dump(hash) }
  end
  b.report("JSON deserialize") do
    n.times { JSON.load(json_hash) }
  end
  b.report("YAML serialize") do
    n.times { YAML.dump(hash) }
  end
  b.report("YAML deserialize") do
    n.times { YAML.load(yaml_hash) }
  end
  require 'psych'
  b.report("Psych serialize") do
    n.times { Psych.dump(hash) }
  end
  b.report("Psych deserialize") do
    n.times { Psych.load(yaml_hash) }
  end
end
