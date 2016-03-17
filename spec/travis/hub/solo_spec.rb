describe Travis::Hub::Solo do
  let(:subject) { described_class.new('solo') }

  describe 'setup' do
    before do
      # XXX: I tend to want to test this without knowing the
      # implementation details, but also don't want to refactor at
      # this stage (ever?).  Hmm...
      Travis::Database.stubs(:connect)
      Travis::Metrics.stubs(:setup)
      Travis::Exceptions::Reporter.stubs(:start)
      Travis::Notification.stubs(:setup)
      Travis::Addons.stubs(:register)
      Travis.config.logs_database = true
      Log.stubs(:establish_connection)
      Log::Part.stubs(:establish_connection)
      subject.stubs(:declare_exchanges_and_queues)
    end

    it 'does not explode' do
      subject.setup
    end
  end

  describe 'run' do
    before do
      subject.stubs(:subscribe_to_queues)
      subject.stubs(:enqueue_jobs)
    end

    it 'enqueues jobs' do
      subject.expects(:enqueue_jobs)
      subject.run
    end

    it 'subscribes to the queue' do
      subject.expects(:subscribe_to_queues)
      subject.run
    end
  end

  describe 'subscribe_to_queue' do
    before do
      Travis::Hub::Queue.stubs(:subscribe)
    end

    it 'subscribes to the jobs queue' do
      Travis::Hub::Queue.expects(:subscribe).with('jobs', 'builds')
      subject.send(:subscribe_to_queues)
    end

    it 'subscribes to the builds queue' do
      Travis::Hub::Queue.expects(:subscribe).with('builds', 'builds')
      subject.send(:subscribe_to_queues)
    end
  end

  describe 'handle_event' do
    context 'when context is jobs' do
      it 'runs update_job service' do
        Travis.expects(:run_service).with(:update_job, event: 'bar', data: 'baz')
        subject.send(:handle_event, 'jobs', 'foo:bar', 'baz')
      end
    end

    context 'when context is builds' do
      it 'runs update_ddtf_build service' do
        Travis.expects(:run_service).with(:update_ddtf_build, event: 'bar', data: 'baz')
        subject.send(:handle_event, 'builds', 'foo:bar', 'baz')
      end
    end
  end
end
