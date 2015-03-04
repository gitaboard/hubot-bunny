try
  {Robot,Adapter,TextMessage,User} = require 'hubot'
catch
  prequire = require('parent-require')
  {Robot,Adapter,TextMessage,User} = prequire 'hubot'
amqp                             = require 'amqp'
util                             = require 'util'

class Bunny extends Adapter

  constructor: ->
    super
    @robot.logger.info "Constructor"

  send: (envelope, strings...) ->
    @robot.logger.info "Send"
    @robot.logger.info "#{util.inspect(envelope)}"
    @robot.logger.info "#{util.inspect(strings[0])}"

  reply: (envelope, strings...) ->
    @robot.logger.info "Reply"

  connect: ->
    @robot.logger.info "Connect"
    # create the connection
    value = null
    connection = amqp.createConnection({host: "localhost", port: 5672})
    connection.on( "ready", () =>
      connection.exchange("hubot.chatops", {}, (exchange) =>
        connection.queue("hubot.commands", {}, (queue) =>
          queue.bind(exchange, "hubot.commands.#")
          queue.subscribe((message, headers, deliveryInfo) =>
            user = new User 1001, name: 'RabbitMQ', queue: queue.name
            message = new TextMessage user, message.data.toString('utf-8'), 'messageId'
            @robot.receive message
            )
          )
        )
      )
    connection.on( "error", (err) ->
      console.error "Something Bad Happened #{err.stack}")

  run: ->
    @robot.logger.info "Run"
    @connect()
    @emit "connected"


exports.use = (robot) ->
  new Bunny robot
