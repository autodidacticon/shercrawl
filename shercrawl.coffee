Cheerio = require 'cheerio'
Promise = require 'bluebird'
Request = Promise.promisifyAll(require 'request')
_ = require 'underscore'

class Shercrawl
  sherdog: 'http://www.sherdog.com'
  shermodel: require('./shermodel')
  fighter_urls: {}
  load_html: (url) =>
    Request.getAsync(url)
    .spread((err, res) ->
      c = Cheerio.load res
      c.url = url
      c)

  get_events: ($) =>
    event_urls = []
    $('table.event a[href]').each ((i,e) ->
      event_urls.push @load_html @sherdog + e.attribs.href
      return).bind(@)
    event_urls
  
  get_fighters: ($) =>
    $('a[href ^= "/fighter"]').each ((i,e) ->
      url = @sherdog + e.attribs.href
      if not _.has @fighter_urls, url
        @fighter_urls[url] = @load_html(url).then(@parse_fighter_data)
      return).bind(@)

  parse_fighter_data: ($) =>
    try
      fighter =
        fighterId: $.url
        name: $('.fn').text(),
        dob: new Date($('span[itemprop="birthDate"]').text()),
        ht: Number( $('span.item.height').text().match(/\d+\.?\d*(?=\scm)/g) ),
        wt: Number( $('span.item.weight').text().match(/\d+\.?\d*(?=\skg)/g) ),
        from: $('span.locality').text(),
        cls: $('strong.title').text(),
        w: Number($('span.result:contains("Wins")').next().text()),
        wko: Number( $('span.result:contains("Wins")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sKO\/TKO)/g) ),
        ws: Number( $('span.result:contains("Wins")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sSUBMISSIONS)/g) ),
        wd: Number( $('span.result:contains("Wins")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sDECISIONS)/g) ),
        wo: Number( $('span.result:contains("Wins")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sDECISIONS)/g) ),
        l: Number($('span.result:contains("Losses")').next().text()),
        lko: Number($('span.result:contains("Losses")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sKO\/TKO)/g)),
        ls: Number( $('span.result:contains("Losses")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sSUBMISSIONS)/g) ),
        ld: Number( $('span.result:contains("Losses")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sDECISIONS)/g) ),
        lo: Number( $('span.result:contains("Losses")').closest('.bio_graph').find('span.graph_tag').text().match(/\d+(?=\sDECISIONS)/g) )
         
      @shermodel.fighter.findOneAndUpdate( name: fighter.name, fighter, upsert: true ).exec()
      
      $('.fight_history').find('tr.odd,tr.even').each ((i,e) ->
        data = $(e).children()
        fight =
          e: @sherdog + data[2]?.firstChild.attribs.href,
          d: new Date $(data[2]?.lastChild).text()
          ref: $(data[3]?.lastChild).text()
          m: $(data[3]?.firstChild).text()
          r: Number $(data[4]?.firstChild).text()

        if $(data[0]?.firstChild).text().trim().toUpperCase() == 'WIN'
          fight.w = $.url
          fight.l = @sherdog + data[1]?.firstChild.attribs.href
        else
          fight.l = $.url
          fight.w = @sherdog + data[1]?.firstChild.attribs.href
          
        t = $(data[5]?.firstChild).text().split ':'
        t = Number t[0] * 60 + Number t[1]
        fight.t = t
        fight.fId = fight.e + '|' + fight.w + '|' + fight.l
        @shermodel.fight.findOneAndUpdate( fId: fight.fId, fight, upsert: true ).exec()
        return).bind @
    catch e
      print e
      print $.url
    return

  run: =>
    url = @sherdog + "/organizations/Ultimate-Fighting-Championship-2"
    @load_html(url)
    .then(@get_events)
    .each(@get_fighters)


module.exports = new Shercrawl()

if require.main == module
  s = new Shercrawl()
  s.run()
