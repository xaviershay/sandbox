# anki-ebird

Use eBird data export to tag bird cards you've seen. For use in a filtered deck:

    "deck:Ultimate Birds::Image to name" tag:observed (is:due OR is:new)

Requires AnkiConnect add on for writing the tags via HTTP API, though reading cards is done directly via database for speed.

Requires installed [Ultimate Birds Deck.](https://ankiweb.net/shared/info/331539617)

Usage:

    # IP address is hard-coded currently, edit to taste.
    bundle exec ruby sync.rb --anki-path /mnt/c/Users/$USER/AppData/Roaming/Anki2/User\ 1/collection.anki2 --ebird-csv data/MyEBirdData-20250420.csv --no-dry-run
