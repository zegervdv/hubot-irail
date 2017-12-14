expect = require('chai').expect
nock = require 'nock'
fs = require 'mz/fs'
moment = require 'moment'
sinon = require 'sinon'

pretend = require 'hubot-pretend'

describe 'irail', =>
  beforeEach =>
    pretend.read './src/irail.coffee'
    pretend.start()
    @alice = pretend.user 'alice'
    process.env.IRAIL_DEFAULT_STATION = "Antwerpen-Centraal"

    @connections_data = JSON.parse await fs.readFile './test/data/connections.json'

    @api = nock 'https://api.irail.be'
    @api.get '/connections'
        .query {
           from: 'Antwerpen-Centraal'
           to: 'Gent-Sint-Pieters'
           timesel: 'departure'
           format: 'json'
        }
        .reply 200, @connections_data

    config =
      now: moment('2017-12-13 20:30:00.000').valueOf()
      shouldAdvanceTime: true
    @clock = sinon.useFakeTimers config
    @time = moment.unix(parseInt @connections_data.connection[0].departure.time)

  afterEach =>
    @clock.restore()
    pretend.shutdown()

  it 'looks up the first trains on a given connection', =>
    await @alice.send '@hubot what is the first train from Antwerpen-Centraal to Gent-Sint-Pieters'
    result = await pretend.observer.next()
    expect(result.value[1]).to.include "The first train leaves at platform #{@connections_data.connection[0].departure.platform} at #{@time.format "H:mm"} (#{@time.fromNow()})"

  it 'looks up the first train to a given destination from the default station', =>
    await @alice.send '@hubot what is the first train to Gent-Sint-Pieters'
    result = await pretend.observer.next()
    expect(result.value[1]).to.include "The first train leaves at platform #{@connections_data.connection[0].departure.platform} at #{@time.format 'H:mm'}"

  it 'can monitor connections for changes'
  it 'starts monitoring 30 mins in advance'
  it 'notifies when disturbances occur on monitored connections'
  it 'nofifies when large disturbances are occuring'

# vim:sw=2:ts=2:et
