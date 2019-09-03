# frozen_string_literal: true
module Binstream
  module Streams
    class FileReader < Base

      def initialize(path_or_io, **kwargs)
        if path_or_io.is_a?(::IO)
          super(path_or_io, **kwargs)
        else
          super(File.open(path_or_io, "rb"), **kwargs)
        end
      end

      def self.open(path, **kwargs)
        return new(File.open(path, "rb"), **kwargs)
      end

      def filepath
        @stream.path
      rescue => e
        nil
      end

      def stell
        @startpos + @cur_offset
      end

      # OVERRIDING

      def peek(length = nil)
        read_size = (length || size)

        if remaining - read_size < 0
          raise StreamOverrunError.new(read_size, remaining, @startpos + @cur_offset)
        end

        resp = @stream.pread(read_size, @startpos + @cur_offset)
        return resp
      end

      def read(length = nil)
        resp = peek(length)
        @cur_offset += resp.bytesize

        return resp
      end
    end
  end
end