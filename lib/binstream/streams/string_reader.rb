# frozen_string_literal: true
module Binstream
  module Streams
    class StringReader < Base
      def initialize(path_or_io, **kwargs)
        if path_or_io.is_a?(::StringIO)
          super(path_or_io, **kwargs)
        else
          super(::StringIO.new(path_or_io, "rb"), **kwargs)
        end
      end
    end
  end
end