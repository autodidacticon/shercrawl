phantom = require 'phantom'

phantom.create (ph) ->
  ph.createPage (page) ->
    page.open "http://www.sherdog.com/organizations/Ultimate-Fighting-Championship-2", (status) ->
      console.log "opened sherdog? ", status
# encapsulate functionality in setTimeout to allow content to load
      setTimeout( (-> 
# evaluate function and log output in callback
        page.evaluate((-> 
          urls = []
          $('table.event a[href]').each (i,e) -> urls.push(e.href)
          return urls), (result) ->
            console.log result[0]
            ph.exit())), 3000 )
