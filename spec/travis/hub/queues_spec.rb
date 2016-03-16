describe Travis::Hub::Queue do
  let(:handler) { ->(*) {} }
  let(:queue)   { Travis::Hub::Queue.new('jobs', 'builds', &handler) }
  let(:payload) { '{ "foo": "bar", "uuid": "2d931510-d99f-494a-8c67-87feb05e1594" }' }
  let(:message) { stub('message', ack: nil, properties: stub('properties', type: 'job:finish')) }

  def receive
    queue.send(:receive, message, payload)
  end

  describe 'subscribe' do
    let(:consumer) { mock('consumer') }

    context 'when context parameter is jobs' do
      before do
        Travis::Amqp::Consumer.stubs(:jobs).returns(consumer)
      end

      it 'subscribes jobs consumer' do
        consumer.expects(:subscribe)
        queue.subscribe
      end
    end

    context 'when context parameter is builds' do
      before do
        Travis::Amqp::Consumer.stubs(:builds).returns(consumer)
      end

      # skipped until we add Amqp::Consumer.builds to travis-support
      xit 'subscribes builds consumer' do
        consumer.expects(:subscribe)
        queue.subscribe
      end
    end
  end

  describe 'receive' do
    it 'sets the given uuid to the current thread' do
      receive
      Thread.current[:uuid].should == '2d931510-d99f-494a-8c67-87feb05e1594'
    end

    describe 'with no exception being raised' do
      context 'when context parameter is jobs' do
        it 'handles job event' do
          handler.expects(:call).with('jobs', 'job:finish', 'foo' => 'bar')
          receive
        end
      end

      context 'when context parameter is builds' do
        let(:queue)   { Travis::Hub::Queue.new('builds', 'builds', &handler) }
        let(:message) { stub('message', ack: nil, properties: stub('properties', type: 'build:finish')) }

        it 'handles build event' do
          handler.expects(:call).with('builds', 'build:finish', 'foo' => 'bar')
          receive
        end
      end

      it 'acknowledges the message' do
        message.expects(:ack)
        receive
      end
    end

    describe 'with an exception being raised' do
      before :each do
        handler.expects(:call).raises(StandardError.new('message'))
        $stdout = StringIO.new
      end

      after :each do
        $stdout = STDOUT
      end

      it 'outputs the exception' do
        receive
        $stdout.string.should =~ /message/
      end

      it 'acknowledges the message' do
        message.expects(:ack)
        receive
      end

      it 'notifies the error reporter' do
        Travis::Exceptions::Reporter.expects(:enqueue).with do |exception|
          $stdout = STDOUT
          exception.should be_instance_of(Travis::Hub::Error)
          exception.message.should =~ /message/
        end
        receive
      end
    end
  end

  describe 'decode' do
    it 'decodes a json payload' do
      queue.send(:decode, '{ "id": 1 }')['id'].should == 1
    end
  end
end
