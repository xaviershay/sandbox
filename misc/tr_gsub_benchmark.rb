require 'benchmark'

n = 100000

Benchmark.bmbm do |x|
  x.report('tr')   { n.times { "created-at".tr(  '-', '_') }}
  x.report('gsub') { n.times { "created-at".gsub('-', '_') }}
end

<<-EOS
~/Code/sandbox/misc (master)$ ruby tr_gsub_benchmark.rb 
Rehearsal ----------------------------------------
tr     0.120000   0.000000   0.120000 (  0.125310)
gsub   0.210000   0.000000   0.210000 (  0.222762)
------------------------------- total: 0.330000sec

           user     system      total        real
tr     0.110000   0.000000   0.110000 (  0.112288)
gsub   0.220000   0.000000   0.220000 (  0.230003)
~/Code/sandbox/misc (master)$ ruby -v
ruby 1.8.6 (2007-09-23 patchlevel 110) [i686-darwin8.11.1]
EOS
