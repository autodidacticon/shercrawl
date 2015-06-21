Shercrawl = require './shercrawl'
Shercrawl.load_html('http://www.sherdog.com/fighter/Chris-Weidman-42804').then(Shercrawl.parse_fighter_data).done(process.exit)
