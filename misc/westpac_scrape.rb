# A script to scrape Westpac Online pages behind the login wall. I want
# to download my statements automatically! I can't get it working though
# - login is all good, but I get redirected to the "No Cookies" page.
#
# Usage:
#   ruby westpac_scrape.rb
require 'rubygems'
require 'mechanize'
require 'json'
require 'logger'
require 'johnson'
require "highline/import"

username = ask("Customer #: ")
password = ask("Password:" ) { |q| q.echo = false }

# The keypad buttons have different values on every page load
# Mappings are included in a JSON object on the page - grep
# that out, parse it, and duplicate the JS logic.
def encode_password(p, key, map)
  p.split(//).map {|x| key[map[x].to_i].chr }.join
end

agent = Mechanize.new{|a| a.log = Logger.new(STDERR) }
page = agent.get('https://online.westpac.com.au/esis/Login/SrvPage')
form = page.forms.detect {|x| x.action == "https://online.westpac.com.au/esis/Login/SrvPage" }

body = page.body

json = JSON.parse(body.grep(/var keypadDef/)[0].gsub(/^var keypadDef = /, '').gsub(/;\s*$/, ''))

password = encode_password(password, json['malgm'], json['keys'])

# This is all mostly done via JS
puts json.inspect
form.action = json['submitToUrl']
form.username_temp = username
form.username = username
form.password_temp = password
form.password = 'w%s*%s' % [password, json['halgm']]
form.halgm = json['halgm']

# A cookie is added via JS, unsure if it is required
def createWestpacIDCookie
  # This JS is from the ui.js, run through JS beautifier and with the cookie checks removed
  js = <<-JS
    var d = new Date();
    var b = new Date(d.getTime() + 365 * 24 * 60 * 60 * 1000 * 3);
    var a = (Math.random() * 1000000);
    CurrentYear = d.getYear();
    if (CurrentYear < 1000) {
        CurrentYear = CurrentYear + 1900
    }
    c = "d" + CurrentYear + (d.getMonth() + 1) + d.getDate() + "t" + d.getHours() + d.getMinutes() + d.getSeconds() + d.getTime() + "r" + Math.floor(a);
    "WestpacID=" + escape(c) + "; expires=" + b.toGMTString() + "; domain=.westpac.com.au;path=/"
  JS

  cookie = Mechanize::Cookie.parse(URI.parse('https://online.westpac.com.au/'), Johnson.evaluate(js))
end

cookie = createWestpacIDCookie[0]
agent.cookie_jar.add(URI.parse('https://online.westpac.com.au/'), cookie) || raise("fail")

# Currently redirects to the No Cookies page, don't know why :(
page = agent.submit(form)

pp page
