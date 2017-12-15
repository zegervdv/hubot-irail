# Description
#  Train information for Hubot
#
# Commands:
#  what is the first train to <location> - Finds the first train departing from default station to <location>
#  what is the first train from <location1> to <location2> - looks for trains

co = require 'co'
superagent = require 'superagent'
moment = require 'moment'

API_URL = 'https://api.irail.be'

class Irail
  constructor: (@robot) ->

  get_connections: () ->
    @robot.brain.get('irail:connections') or {}

  save_connections: (data) ->
    @robot.brain.set 'irail:connections', data

  find_connection: (station, from = process.env.IRAIL_DEFAULT_STATION) ->
    opts =
      from: from
      to: station
      timesel: 'departure'
      format: 'json'

    superagent.get "#{API_URL}/connections"
      .query opts
    .then (data) =>
      JSON.parse(data.text).connection[0]

  register_connection: (time, dest) ->
    throw Error("You need to configure a default station for this feature") unless process.env.IRAIL_DEFAULT_STATION?
    time = time.replace ':', ''
    co =>
      hash = @hash_key time, dest, process.env.IRAIL_DEFAULT_STATION
      opts =
        from: process.env.IRAIL_DEFAULT_STATION
        to: dest
        timesel: 'departure'
        format: 'json'
        time: time
      connection = yield superagent.get "#{API_URL}/connections"
                                   .query opts
      throw Error('No such connection') unless connection.ok
      connections = @get_connections()
      connections[hash] =
        time: time
        source: process.env.IRAIL_DEFAULT_STATION
        dest: dest
      @save_connections connections

  hash_key: (time, dest, src) ->
    return "#{time}_#{dest}_#{src}"

module.exports = (robot) ->
  irail = new Irail robot
  robot.irail = irail

  robot.respond /what is the first train( from )?([^ ]*)? to ([^ ]*)\??/i, (res) =>
    from = res.match[2] || process.env.IRAIL_DEFAULT_STATION
    station = res.match[3]
    co =>
      connection = yield irail.find_connection station, from
      time = moment.unix parseInt connection.departure.time
      msg = "The first train leaves at platform #{connection.departure.platform} at #{time.format 'H:mm'} (#{time.fromNow()})"

      res.reply msg
    .catch (err) =>
      robot.logger.error err
      robot.logger.debug err.stack
      res.reply "I could not find anything from `#{from}`  to `#{station}`."

  robot.respond /alert me for the ([\d:]+) train to ([^ ]+)/i, (res) ->
    [_, time, dest] = res.match
    co =>
      yield irail.register_connection time, dest
    .then =>
      res.reply "Monitoring your connection"
    .catch (err) =>
      @robot.logger.error err
      @robot.logger.error err.stack
      res.reply "Could not find this connection"


  return robot.irail

# vim:sw=2:ts=2:et
