# The perfect solution for a needy girlfriend
# Repeatedly emails *cuddle* with a random interval
i = 1
while true
  cmd = "echo \"*cuddle*\" | mail -s \"Cuddle ##{i}\" #{ENV["EMAIL"]}"
  puts cmd
  `#{cmd}`
  i += 1
  sleep 60 * (rand * 30 + 30)
end
