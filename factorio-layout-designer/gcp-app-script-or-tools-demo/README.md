This is a proof-of-concept calling an App Script function from a web page.

Motivation is to get access to or-tools, which isn't available natively in JS.
Since App Script already has access to OrTools via a service, seemed like might
be the easiest way to expose it without having to host my own web service or
otherwise wrap it.

`ortools-appscript.gs` must be the source for an App Script in google drive,
which is then published as API executable runnable by anyone.

Serve this directory (`python -m SimpleHTTPServer 8000`). Edit `index.html` with:

1. An OAuth client secret for web app, with `localhost:8000` an allowed
   referred (docs suggest "other" should work, but this wasn't true in my
   experience - complained about not having allowed referer).
2. An API key (separate from OAuth client)
3. Customize the `scriptId` to match the ID off App script (`File -> Project
   Properties`). Note the "API ID" it gives you after deploying as API
   executable is useless and not what you want here..

See https://console.cloud.google.com/apis/credentials to create.

Initial thoughts: overall a bit janky but seems to work.

* Requires google authentication, but probably fine since wanted that for storage anyway.
* Seems kind of slow? 2.5s slow?
* The AppScript editor is janky af, but hopefully shouldn't need to change this
  code often - made it as thin a wrapper around or-tools as possible.
* debugMode option to script.run doesn't work (errors), and "updating" an
  existing API doesn't work either (probably works with long enough cache
  expiry?). Need to publish a new API version to test each new change.

Probably a better option would be an AWS lambda (faster, possibly easier to
call as REST endpoint) - someone has already built an or-tools python layer ...
but it doesn't appear to work and I can't figure out why :(
