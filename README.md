[![Build Status](https://travis-ci.org/AVGTechnologies/travis-hub.svg?branch=master)](https://travis-ci.org/AVGTechnologies/travis-hub)

# What is Travis Hub

Travis Hub collects build logs, state changes and other information from Travis workers, then updates build logs
in the database, propagates messages to browsers via [Pusher](http://pusher.com), detects finished builds, delivers email and IRC notifications,
bakes you a pizza and walks your dog.

## Dependencies

### RabbitMQ

Travis Hub communicates with other applications using [RabbitMQ](http://rabbitmq.com) (via [Hot Bunnies](https://github.com/ruby-amqp/hot_bunnies)).
Please refer to [amqp gem's Getting Started guide](http://rubyamqp.info/articles/getting_started/) to learn [how to install RabbitMQ](http://rubyamqp.info/articles/getting_started/#installing_rabbitmq) on your platform,
we won't duplicate all that information here.

After you have RabbitMQ running, use

    ./script/set_rabbitmq_env_up.sh

to create a separate RabbitMQ vhost (travis.development) for travis as well as one user (`travis_hub`) for Hub.
You can instead use any other vhost or username but this script matches what's in the example configuration
file.


### JRuby and libraries

Travis Hub is JRuby-based. Make sure you have Sun or OpenJDK 6, install JRuby via RVM (or any other way) and then do

    bundle install

Hub uses [travis-core](https://github.com/travis-ci/travis-core) and [travis-support](https://github.com/travis-ci/travis-support) that evolve
rapidly, so keep your eye on those two.


### Deploying on Heroku

Heroku will detect the JRuby version from the `Gemfile`.  The following `JAVA_OPTS` may be set for a typical deployment:

    heroku config:add JAVA_OPTS="-Xmx768m -Xss512k -XX:+UseCompressedOops -Dfile.encoding=UTF-8"

### PostgreSQL

Primary database used by travis-ci.org is PostgreSQL and Hub uses it extensively. While we use 9.0 in production, 8.4 and 9.1 will work
just as well.

The schema required by hub lives over in [travis-core](https://github.com/travis-ci/travis-core) and can be created by running migrations in
that project.


## Configuration

Hub uses multiple services that require configuration. It loads configuration from `config/travis.yml` and keeps
configs for all environments (development, test, production) in one file under different keys:

    development:
      # development configuration goes here

    test:
      # test configuration goes here

    staging:
      # staging configuration goes here

    production:
      # production configuration goes here

Find a sample travis.yml file under config/travis.example.yml, copy it and edit it to match your system.


## Running Hub

To run Hub in the foreground, use

    bin/hub solo

There are two modes: Either a single process handling everything, or a one dispatcher, multiple workers setup:

    bin/hub dispatcher 2
    bin/hub worker 1
    bin/hub worker 2

### Scaling up and down

When scaling down, keep in mind to first let the queue drain before killing off workers.

On Heroku, scaling works like this:

    heroku config:set DYNO_COUNT=2
    heroku ps:scale solo=0 dispatcher=1:2x worker=2:2x

## Disabling Features

Quite often during development you want to disable things like email delivery and [Pusher](http://pusher.com/) notifications.
Hub lets you do that by removing certain listeners in the configuration file:

    development:
      domain: travis-ci.local
      notifications:
        - worker
        - pusher
        - email
        - irc
        - webhook
        - campfire
        - archive

To disable Pusher, email and IRC notifications, just remove several lines like this:


    development:
      domain: travis-ci.local
      notifications:
        - worker
        - webhook
        - campfire
        - archive

### Worker listener

This is the only listener that is not optional. It processes build configuration messages and
publishes one or more build requests (think matrix rows) to workers. In real world scenarios this
listener cannot be left out.

### Pusher listener

Propagates messages to browsers using Pusher. Often disabled during development.

### Email listener

Delivers email notifications. Usually disabled during development.

### IRC listener

Delivers IRC notifications. Usually disabled during development.

### Web Hooks listener

Delivers Web hooks notifications, a la GitHub hooks. Usually disabled during development.

### Campfire listener

Delivers Campfire notifications. Usually disabled during development.

### Archive listener

Proactively archives build logs & other information to a separate data store.
Usually disabled during development.

## Contributing

See the CONTRIBUTING.md file for information on how to contribute to travis-hub.
Note that we're using a [central issue tracker]
(https://github.com/travis-ci/travis-ci/issues) for all the Travis projects.


## License & copyright information ##

See LICENSE file.

Copyright (c) 2011-2013 [Travis CI development team](https://github.com/travis-ci).
