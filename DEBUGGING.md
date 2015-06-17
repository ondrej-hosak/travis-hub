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

Simulate  receive\_request
--------------------------

     payload = JSON.load(File.read('/home/lukas/projects/travis/travis-listener/stash-payload.json'))
     payload['refChange'] = payload['refChanges'].first
     req = Travis.service(:receive_request, User.first, { :type => 'push', payload: payload, uuid: Travis.uuid, provider: 'stash'}).run

Get payload sended to the worker
--------------------------------

     job = Job.last
     Travis::Api.data(job, { :'for' => 'worker', type: 'Job::Test', version: 'v0'} )


Enqueue jobs
------------

     Travis.service(:enqueue_jobs).run


Trableshootings
---------------

1. `OpenSSL::Cipher::CipherError: Illegal key size: possibly you need to install Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files for your JRE`

  Do not use oracle java:

     sudo apt-get install openjdk-7-jre-headless # on server
     sudo apt-get install openjdk-7-jdk openjdk-7-source # on developer machine
     sudo update-alternatives --set java /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java

  .. or install JCE, ...or workaround:

     security_class = java.lang.Class.for_name('javax.crypto.JceSecurity')
     restricted_field = security_class.get_declared_field('isRestricted')
     restricted_field.accessible = true
     restricted_field.set nil, false
