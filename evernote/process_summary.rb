require 'csv'

months = %W(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
puts "<table class='charts-css column multiple show-labels'>"
CSV.foreach(File.expand_path("~/Downloads/music-summary.csv"), headers: true) do |row|
  month_short = months.fetch(row["Month"].to_i - 1)
  next unless month_short
  puts <<-HTML
    <tr>
      <th scope="row">#{month_short}</th>
      <td style="--size:calc(#{row['Trombone']} / 12)"><span class="data">#{row['Trombone']}</span></td>
      <td style="--size:calc(#{row['Piano']} / 12)"><span class="data">#{row['Piano']}</span></td>
    </tr>
  HTML
end

puts "</table>"
