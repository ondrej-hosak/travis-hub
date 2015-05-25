solo:       ./bin/hub solo
dispatcher: ./bin/hub dispatcher $DYNO_COUNT
worker:     ./bin/hub worker $DYNO_COUNT $DYNO
enqueue:    ./bin/hub enqueue
build_request: bundle exec sidekiq -c 5 -r ./lib/travis/receive-request.rb -q build_requests
