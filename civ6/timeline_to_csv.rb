require 'json'
require 'csv'
require 'set'
require 'pp'

filename = ARGV.shift
leader_name = ARGV.shift
contents = File.read(filename)
data = JSON.parse(contents)
date = File.basename(filename).split('-').take(3).join('-')
leader = File.basename(filename, ".json").split('-', 5).last
game_id = "%s (%s)" % [leader, date]

player = data.fetch("Players").detect {|x| x.fetch("LeaderName") == leader_name } || data.fetch("Players").first

player_id = player.fetch("Id")

moments = data.fetch("Moments")

ignored_moments = Set.new(%w(
  MOMENT_BATTLE_FOUGHT
  MOMENT_SHIP_SUNK
))

cumulative_score = 0

output = CSV.generate do |csv|
  moments.select {|x| x.fetch("ActingPlayer") == player_id }.each do |moment|
    score = moment.fetch("EraScore")
    era = moment.fetch("GameEra")
    type = moment.fetch("Type")
    turn = moment.fetch("Turn")
    cumulative_score += score

    next if ignored_moments.include?(type)

    csv << [game_id, turn, era, type, score, cumulative_score]
  end
end
puts output
