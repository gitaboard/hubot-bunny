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
    @connection = amqp.createConnection({host: "localhost", port: 5672})
    @robot.logger.info "Constructor"

  send: (envelope, strings...) ->
    @robot.logger.info "Send"
    @robot.logger.info "#{util.inspect(envelope)}"
    @robot.logger.info "#{util.inspect(strings[0])}"
    @connection.exchange("hubot.chatops", {type: 'direct', autoDelete: 'true'}, (exchange) =>
      @robot.logger.info "Exchange Created..."
      exchange.publish("repositories.sample", strings[0])
      )


  reply: (envelope, strings...) ->
    @robot.logger.info "Reply"

  connect: ->
    @robot.logger.info "Connect"
    # create the connection
    value = null

    @connection.on( "ready", () =>
      @connection.exchange("hubot.chatops", {type: 'direct', autoDelete: 'true'}, (exchange) =>
        @connection.queue("hubot.inbound", {}, (queue) =>
          queue.bind(exchange, "repositories.sample")
          queue.subscribe((message, headers, deliveryInfo) =>
            user = new User 1001, name: 'RabbitMQ', queue: queue.name
            message = new TextMessage user, message.data.toString('utf-8'), 'messageId'
            @robot.receive message
            )
          )
        )
      )
    @connection.on( "error", (err) ->
      console.error "Something Bad Happened #{err.stack}")

  run: ->
    @robot.logger.info "Run"
    @connect()
    @emit "connected"


exports.use = (robot) ->
  new Bunny robot
