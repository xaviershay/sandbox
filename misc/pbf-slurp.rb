require 'rubygems'

# Get list of images
require 'hpricot'
require 'open-uri'

url = "http://pbfcomics.com/"
doc = Hpricot(open(url))

(doc/"center div a").each do |results|
  uri = 'archive/' + results[:href].gsub(/.*PBF/, 'PBF').gsub(/#.*/, '') if results[:href]
  `wget #{url}#{uri}` if uri
  uri = nil
end
