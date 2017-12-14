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


  return robot.irail

# vim:sw=2:ts=2:et
