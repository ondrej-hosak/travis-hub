require 'sidekiq'
require 'travis'
require 'travis/support/amqp'
require 'travis-sidekiqs'



Travis::Async.enabled = true
Travis::Amqp.config = Travis.config.amqp

Travis.logger.info('[receive-request] connecting to database')
Travis::Database.connect

if Travis.config.logs_database
  Travis.logger.info('[receive-request] connecting to logs database')
  Log.establish_connection 'logs_database'
  Log::Part.establish_connection 'logs_database'
end

Travis.logger.info('[receive-request] setting up sidekiq')
# The client pushes jobs onto the queue. The server pulls jobs and processes them
# e.g. this is the server. Setting up clinet as well becase some service could
# call sidekiq as well
Sidekiq.configure_server do |config|
  config.redis = Travis.config.redis.merge(namespace: Travis.config.sidekiq.namespace)
end
Travis::Async::Sidekiq.setup(Travis.config.redis.url, Travis.config.sidekiq)

Travis.logger.info('[receive-request] starting exceptions reporter')
Travis::Exceptions::Reporter.start

Travis.logger.info('[receive-request] setting up metrics')
Travis::Metrics.setup

Travis.logger.info('[receive-request] setting up notifications')
Travis::Notification.setup

Travis.logger.info('[receive-request] setting up addons')
Travis::Addons.register

