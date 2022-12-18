require 'nokogiri'
require 'date'
require 'pp'
require 'json'

# Open the XML file
file = File.open(File.expand_path('~/Documents/Evernote.enex'))

# Parse the XML document using Nokogiri
doc = Nokogiri::XML(file)

# Find all the "note" elements
notes = doc.xpath("//note")

# Filter the notes by those that have a "title" subtag matching the regex /^Piano/
filtered_notes = notes.select do |note|
  title = note.at_xpath("./title")
  title && title.text =~ /^(Piano|Trombone)/
end

err = $stderr
err = StringIO.new("")

time_regex = /(\d+)(?:ish)? ?min/

result = []

# Extract the text content of the "title" subtag for each filtered note
filtered_notes.each do |note|
  title = note.at_xpath("./title")
  created = Date.parse(note.at_xpath("./created"))
  next if created < Date.new(2022,1,1)

  string = title.text
  instrument = string.split(' ')[0]

  # Use a regular expression to match the date
  date_regex = /\b(?<month>\w+)\s+(?<day>\d+)\b/
  match = date_regex.match(string)

  if match
    # Extract the month and day from the match
    month = match[:month]
    day = match[:day]

    year = created.year
    date = Date.new(year, Date::MONTHNAMES.index(month), day.to_i) rescue nil

    if created && date && (created - date).abs <= 2
      xml_content = note.at_xpath("./content")
      content = Nokogiri::XML(xml_content)
      time = content.text.match(time_regex)
      if time
        minutes = time[0].to_i
      else
        if content.text.match(/lesson|band/i)
          minutes = 60
        else
          minutes = 5
          # err.puts "TIME ERROR: %s - %s" % [title.text, content.text[0..100]]
          # next
        end
      end

      result.push(
        instrument: instrument,
        minutes: minutes,
        date: date
      )
      # puts "%s - %imin %s" % [
      #   title.text,
      #   minutes,
      #   date
      # ]
    else
      err.puts "ERROR: %s - %s %s" % [
        title.text,
        created,
        date
      ]
    end
  else
    err.puts "ERROR: #{title.text}"
  end
end

puts JSON.pretty_generate(result)
# Close the file
file.close
