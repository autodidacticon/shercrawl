jsdom = require "jsdom"
_ = require "underscore"
s = require('./shermodel').Shermodel()
event_urls = {}
fighter_urls = {}

shercrawl = shercrawl || {}

shercrawl.jsdominator = (url,fn,scripts) ->
  require('jsdom').env
    url: url,
    scripts: ["http://code.jquery.com/jquery.js"],
    done: (e,w) ->
      if e
        console.log e
        return
      fn e,w
      w.close()
  return

shercrawl.get_fighters_from = (event_urls) ->
  for event in _.keys(event_urls)
    shercrawl.jsdominator event,
      (e,w) ->
        $ = w.$
        $('a[href ^= "/fighter"]').each (i,e) ->
          if not _.has fighter_urls, e.href
            fighter_urls[e.href] = false
            shercrawl.parse_fighter_data_from e.href
        event_urls[event] = true
        return
  return

shercrawl.parse_fighter_data_from = (fighter_url, force = true) ->
  if not force and not s.fighter.findOne(fighterId: fighter_url)
    #fighter exists
    return
  shercrawl.jsdominator fighter_url,
    (e,w) ->
      $ = w.$
      fighter =
        fighterId: fighter_url,
        n: $('.fn').text(),
        dob: new Date($('span[itemprop="birthDate"]').text()),
        ht: $('span.item.height').text().match(/\d+\.?\d*(?=\scm)/g),
        wt: $('span.item.weight').text().match(/\d+\.?\d*(?=\skg)/g),
        from: $('span.locality').text(),
        cls: $('strong.title').text(),
        w: Number($('span.result:contains("Wins")').next().text()),
        wko: $('span.result:contains("Wins")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sKO\/TKO)/g),
        ws: $('span.result:contains("Wins")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sSUBMISSIONS)/g),
        wd: $('span.result:contains("Wins")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sDECISIONS)/g),
        wo: $('span.result:contains("Wins")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sDECISIONS)/g),
        l: Number($('span.result:contains("Losses")').next().text()),
        lko: $('span.result:contains("Losses")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sKO\/TKO)/g),
        ls: $('span.result:contains("Losses")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sSUBMISSIONS)/g),
        ld: $('span.result:contains("Losses")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sDECISIONS)/g),
        lo: $('span.result:contains("Losses")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sDECISIONS)/g),
      for key in _.keys fighter
        if typeof fighter[key] == 'object' and fighter[key] != null and fighter[key].hasOwnProperty 'length'
          fighter[key] = Number fighter[key][0]
         
      console.log s.fighter.findOneAndUpdate( fighterId: fighter_url, fighter, upsert: true ).exec()
      delete fighter_urls[fighter_url]
      
      $('.fight_history').find('tr.odd,tr.even').each (i,e) ->
        data = e.children
        fight =
          e: data[2].firstChild.href,
          d: new Date(data[2].lastChild.textContent)
          ref: data[3].lastChild.textContent
          m: data[3].firstChild.textContent
          r: Number data[4].firstChild.textContent

        if data[0].firstChild.textContent.trim().toUpperCase() == 'WIN'
          fight.w = fighter_url
          fight.l = data[1].firstChild.href
        else
          fight.l = fighter_url
          fight.w = data[1].firstChild.href
          
        t = data[5].firstChild.textContent.split ':'
        t = t[0] * 60 + t[1]
        fight.t = t

        fight.fId = fight.e + '|' + fight.w + '|' + fight.l
        console.log s.fight.findOneAndUpdate( fId: fight.fId, fight, upsert: true ).exec()
        return
      return

exports.shercrawl = shercrawl

exports.run = ->
  shercrawl.jsdominator "http://www.sherdog.com/organizations/Ultimate-Fighting-Championship-2",
    (e,w) ->
      $ = w.$
      $('table.event a[href]').each (i,e) ->
        event_urls[e.href] = false
        return
      shercrawl.get_fighters_from event_urls
      return



if require.main == module
  this.run()
