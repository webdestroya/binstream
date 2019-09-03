module Binstream
  module Tracking
    def self.included(base)
      base.extend(ClassMethods)
    end

    def track(message = nil, &block)
      ::Binstream::Tracker.instance.track(message, &block)
    end

    def track_pos(stream)
      track do 
        "Pos=#{stream.tell}"
      end
    end

    def without_tracking(&block)
      old_val = ::Binstream::Tracker.instance.enabled?
      ::Binstream::Tracker.instance.enabled = false
      yield
    ensure
      ::Binstream::Tracker.instance.enabled = old_val
    end

    module ClassMethods
      def track(message = nil, &block)
        ::Binstream::Tracker.instance.track(message, &block)
      end
    end
  end
end