# This script takes a list of seen birds from eBird "Download my data", and tags those birds as "observed" in Anki.
# It is quite janky, and was written to "technically works" standard.
# Originally it used direct insertion to Anki's sqlite3 database, but that isn't sufficient to update tag indexes such that cards show up in searches.
# It now uses AnkiConnect, and add-on to Anki, which is horrendously slow but
# does technically work. Mostly. It appears to break on birds with large tag
# sets (e.g. pigeon) which I had to do manually.
#
# Will need to modify ANKI_CONNECT_URL to correct IP.

require 'sqlite3'
require 'pathname'
require 'optparse'
require 'set'
require 'csv'
require 'net/http'
require 'json'
require 'shellwords'

class AnkiEBirdTagger
  ANKI_CONNECT_URL = 'http://192.168.1.164:8765/'

  def initialize(anki_path:, ebird_csv_path:)
    @anki_path = Pathname.new(anki_path)
    @ebird_csv_path = Pathname.new(ebird_csv_path)
  end

  def print_curl_command(method:, url:, data: nil)
    command = ['curl', '-X', method]
    
    # Add headers and data if present
    if data
      command.push('-H', 'Content-Type: application/json')
      command.push('-d', data.to_json)
    end
    
    # Add URL
    command.push(url)
    
    # Print the command with proper shell escaping
    puts "\nEquivalent curl command:"
    puts command.map { |arg| Shellwords.escape(arg) }.join(' ')
    puts
  end

  def anki_connect_request(action:, params: {}, version: 6)
    data = {
      action: action,
      version: version,
      params: params
    }

    # print_curl_command(
    #   method: 'POST',
    #   url: ANKI_CONNECT_URL,
    #   data: data
    # )

    uri = URI(ANKI_CONNECT_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json'
    request.body = data.to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise "AnkiConnect error: #{response.code} - #{response.message}"
    end

    result = JSON.parse(response.body)
    if result['error']
      raise "AnkiConnect error: #{result['error']}"
    end
    
    result['result']
  end

  def extract_card_data
    puts "Finding 'Ultimate Birds' deck..."
    db = SQLite3::Database.new(@anki_path.to_s)
    db.results_as_hash = true

    # Get deck ID
    deck_id = db.get_first_value("SELECT id FROM decks WHERE name LIKE 'Ultimate Birds%Image to name' COLLATE NOCASE")
    raise "Could not find 'Ultimate Birds' deck" unless deck_id

    # Get all cards and their note data
    rows = db.execute(<<-SQL, [deck_id])
      SELECT n.id, n.flds, n.tags
      FROM cards c
      JOIN notes n ON c.nid = n.id
      WHERE c.did = ?
    SQL

    card_data = {}
    rows.each do |row|
      fields = row['flds'].split("\x1f")  # Anki uses \x1f as field separator
      common_name = fields[0].strip
      
      card_data[common_name] = {
        note_id: row['id'],
        tags: row['tags'].to_s
      }
    end

    puts "Found #{card_data.length} cards with common names"
    card_data
  ensure
    db&.close
  end

  def get_observed_species
    puts "Reading eBird CSV data..."
    
    observed_species = Set.new
    species_dates = Hash.new { |h, k| h[k] = [] }
    
    CSV.foreach(@ebird_csv_path, headers: true) do |row|
      common_name = row['Common Name']
      date = row['Date']
      next unless common_name && date
      
      observed_species.add(common_name)
      species_dates[common_name] << date
    end

    puts "Found #{observed_species.size} observed species in CSV"
    [observed_species, species_dates]
  end

  def update_note_tags(note_id:, tags:, dry_run: true)
    return if dry_run

    anki_connect_request(
      action: 'updateNoteTags',
      params: {
        note: note_id,
        tags: tags.split
      }
    )
  end

  # Not sure how this would happen yet, but differences in names between data sets
  REPLACEMENTS = {
    "Rock Pigeon (Feral Pigeon)" => "Rock Pigeon",
    "Australasian/Hoary-headed Grebe" => "Australasian Grebe",
    "Mallard (Domestic type)" => "Mallard",
    "Muscovy Duck (Domestic type)" => "Muscovy Duck",
    "Eastern Cattle-Egret" => "Eastern Cattle Egret"
  }

  def tag_observed_cards(dry_run: true)
    # Get data from both sources
    card_data = extract_card_data
    observed_species, species_dates = get_observed_species

    # Analyze what needs to be updated
    to_update = []
    already_tagged = []
    
    observed_species.sort.each do |common_name|
      common_name = REPLACEMENTS[common_name] || common_name
      data = card_data.fetch(common_name)

      current_tags = data[:tags].split
      
      dates = species_dates[common_name]
      first_date = dates.min
      last_date = dates.max
      observation_count = dates.size
      
      if current_tags.include?('observed')
        already_tagged << common_name
        puts "Already tagged: #{common_name}"
      else
        # Create a detailed observed tag with first and last observation dates
        new_tags = current_tags + ['observed']
        new_tags = new_tags.sort.uniq.join(' ')
        
        to_update << {
          note_id: data[:note_id],
          new_tags: new_tags,
          common_name: common_name,
          first_date: first_date,
          last_date: last_date,
          observation_count: observation_count
        }
      end
    end

    # Print summary
    puts "\nAnalysis Summary:"
    puts "=" * 50
    puts "Total cards in deck: #{card_data.length}"
    puts "Total observed species in CSV: #{observed_species.size}"
    puts "Cards needing updates: #{to_update.length}"
    puts "Cards already tagged: #{already_tagged.length}"

    # Print detailed changes
    if to_update.any?
      puts "\nProposed Changes:"
      puts "=" * 50
      to_update.each do |update|
        puts "+ Adding tags to: #{update[:common_name]}"
        puts "  First seen: #{update[:first_date]}"
        puts "  Last seen: #{update[:last_date]}"
        puts "  Total observations: #{update[:observation_count]}"
      end
    end

    if dry_run
      puts "\nDRY RUN - No changes made to Anki database"
      return
    end

    # Make actual updates
    puts "\nApplying changes to Anki database..."
    
    to_update.each.with_index do |update, n|
      puts "#{n+1}/#{to_update.length}: #{update[:common_name]}"
      update_note_tags(
        note_id: update[:note_id],
        tags: update[:new_tags],
        dry_run: dry_run
      )
    end

    puts "Successfully updated #{to_update.length} cards!"
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  
  OptionParser.new do |opts|
    opts.banner = "Usage: ruby anki_ebird_tagger.rb [options]"

    opts.on("--anki-path PATH", "Path to Anki collection.anki2 file") do |path|
      options[:anki_path] = path
    end

    opts.on("--ebird-csv PATH", "Path to eBird CSV export file") do |path|
      options[:ebird_csv_path] = path
    end

    opts.on("--[no-]dry-run", "Show what would be updated without making changes") do |dry_run|
      options[:dry_run] = dry_run
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!

  unless options[:anki_path] && options[:ebird_csv_path]
    puts "Error: --anki-path and --ebird-csv-path are required"
    puts "Use --help for usage information"
    exit 1
  end

  tagger = AnkiEBirdTagger.new(
    anki_path: options[:anki_path],
    ebird_csv_path: options[:ebird_csv_path]
  )
  tagger.tag_observed_cards(dry_run: options.fetch(:dry_run, true))
end