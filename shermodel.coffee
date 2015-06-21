mongoose = require 'mongoose'
connect = (user, pass, host = 'localhost', port = '27017', database = 'sherdata') ->
  conn_string = host + ':' + port + '/' + database
  if user and pass
    conn_string = user + ':' + pass + '@' + conn_string
  connection = mongoose.createConnection 'mongodb://' + conn_string

eventSchema = mongoose.Schema
    name: String,
    d: Date,
    l: String,
    fs: [],
    eId: String

fighterSchema = mongoose.Schema
    fighterId: String,
    name: String,
    dob: Date,
    ht: Number,
    wt: Number,
    from: String,
    cls: String,
    w: Number,
    wko: Number,
    ws: Number,
    wd: Number,
    wo: Number,
    l: Number,
    lko: Number,
    ls: Number,
    ld: Number,
    lo: Number

fighterSchema.index fighterId: 1

fightSchema = mongoose.Schema
    w: String,
    l: String,
    e: String,
    m: String,
    ref: String,
    r: Number,
    t: Number,
    fId: String,
    d: Date

module.exports = ((connection = connect()) ->
  fighter: connection.model('fighter', fighterSchema)

  fight: connection.model('fight', fightSchema)

  event: connection.model('event', eventSchema)

  disconnect: ->
    connection.disconnect())()
