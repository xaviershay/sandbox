# A proof of concept approach for logging in to Westpac Online Banking
require 'mechanize'
require 'json'
require 'highline'

EAM_URL = 'https://banking.westpac.com.au/eam/servlet/getEamInterfaceData'
SUBMIT_URL = 'https://banking.westpac.com.au/eam/servlet/AuthenticateHttpServlet'
LOGIN_URL = 'https://banking.westpac.com.au/wbc/banking/handler?TAM_OP=login&logout=false'

cli = HighLine.new

username = cli.ask("Enter your username:  ")
unencoded_password = cli.ask("Enter your password:  ") { |q| q.echo = "x" }
unencoded_password.upcase!

# The keypad buttons have different values on every page load
# Mappings are included in a JSON object on the page - grep
# that out, parse it, and duplicate the JS logic.
def encode_password(p, key, map)
  p.split(//).map {|x| key[map[x].to_i].chr }.join
end

agent = Mechanize.new

json = JSON.parse(agent.get(EAM_URL).body)

keymap = {}
json["keymap"]['keys'].each do |key_mapping|
  keymap.merge!(key_mapping)
end

page = agent.get(LOGIN_URL)
form = page.forms.first


password = encode_password(unencoded_password, json["keymap"]['malgm'], keymap)

form.action = SUBMIT_URL
form.username = username
form.password = password
form.add_field!("halgm", json["keymap"]['halgm'])

page = agent.submit(form)

puts "Account details: #{page.search(".tf-account-detail").text}"
puts "Account balance: #{page.search(".balance.current .balance").text}"
