Debugging
=========

IRB Setup
---------

     $: << 'lib'
     require 'bundler/setup'
     require 'travis/hub'
     app = Travis::Hub.new('solo')
     app.setup

One line (for copy & paste):

     $: << 'lib'; require 'bundler/setup'; require 'travis/hub'; app = Travis::Hub.new('solo'); app.setup

Simulate  receive\_request:

     payload = JSON.load(File.read('/home/lukas/projects/travis/travis-listener/stash-payload.json'))
     req = Travis.service(:receive_request, User.first, { :type => 'push', payload: payload, uuid: Travis.uuid, provider: 'stash'}).run


Enqueu jobs:

     Travis.service(:enqueue_jobs).run
