require 'coder'

module Travis
  module Hub
    class Queue
      include Logging

      def self.subscribe(context, queue, &handler)
        new(context, queue, &handler).subscribe
      end

      attr_reader :handler, :queue, :context

      def initialize(context, queue, &handler)
        @context = context
        @queue   = queue
        @handler = handler
      end

      def subscribe
        Travis.logger.info('[hub] subscribing to %p' % queue)
        case @context
        when 'jobs'
          Travis::Amqp::Consumer.jobs(queue).subscribe(ack: true, &method(:receive))
        when 'builds'
          Travis::Amqp::Consumer.builds(queue).subscribe(ack: true, &method(:receive))
        end
        Travis.logger.info('[hub] subscribed')
      end

      private

        def receive(message, payload)
          failsafe(message, payload) do
            event = message.properties.type
            payload = decode(payload) || fail("no payload for #{event.inspect} (#{message.inspect})")
            Travis.uuid = payload.delete('uuid')
            handler.call(context, event, payload)
          end
        end

        def failsafe(message, payload, options = {}, &block)
          Timeout.timeout(options[:timeout] || 60, &block)
        rescue => e
          begin
            puts e.message, e.backtrace
            Travis::Exceptions.handle(Hub::Error.new(message.properties.type, payload, e))
          rescue => e
            puts "!!!FAILSAFE!!! #{e.message}", e.backtrace
          end
        ensure
          message.ack
        end

        def decode(payload)
          cleaned = Coder.clean(payload)
          MultiJson.decode(cleaned)
        rescue StandardError => e
          error '[decode error] payload could not be decoded with engine ' \
                "#{MultiJson.engine}: #{e.inspect} #{payload.inspect}"
          nil
        end
    end
  end
end
