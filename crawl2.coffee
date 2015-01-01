jsdom = require "jsdom"
_ = require "underscore"
event_urls = {}
fighter_urls = {}
jsdom.env(
  url: "http://sherdog.com/organizations/Ultimate-Fighting-Championship-2"
  scripts: ["http://code.jquery.com/jquery.js"],
  done: (e,w) ->
    $ = w.$
    $('table.event a[href]').each (i,e) ->
      event_urls[e.href] = false
      return
    w.close()
    get_fighters_from event_urls
)

get_fighters_from = (event_urls) ->
  for event in _.keys(event_urls)
    require("jsdom").env(
      url: event,
      scripts: ["http://code.jquery.com/jquery.js"],
      done: (e,w) ->
        $ = w.$
        if $
          $('a[href ^= "/fighter"]').each (i,e) ->
            if not _.has fighter_urls, e.href
              fighter_urls[e.href] = false
        event_urls[event] = true
        w.close()
    )
  return
