# frozen_string_literal: true
module Binstream
  module Streams
    class Base
      extend Forwardable
      include Tracking

      def_delegators :@stream, :close
      attr_reader :stopper

      def initialize(stream, startpos: nil, whence: IO::SEEK_SET, read_length: nil, **kwargs)
        @stream = stream
        reset
        setup_stopper(startpos, whence, read_length)
      end

      def setup_stopper(startpos, whence, max_length)
        if whence == IO::SEEK_CUR
          startpos += @stream.tell
        end

        @startpos = startpos || @stream.tell

        if max_length
          @stopper = startpos + max_length
        else
          @stopper = @stream.size
        end
      end

      def starting_offset
        @startpos
      end

      def reset
        @cur_offset = 0
        @stopper = nil
        @startpos = 0
      end

      # Create a new stream based off this one using an offset and length
      def slice(new_length, new_offset=nil)
        new_stream = peek_slice(new_length, new_offset)
        
        # advance our pointer
        @cur_offset += new_length

        return new_stream
      end

      # slice!(length, offset)
      # Get new stream using absolute position
      def slice!(new_length, new_offset)
        self.class.new(@stream, 
          startpos: (@startpos + new_offset), 
          read_length: new_length
        )
      end

      # Get a new stream at the current position, but don't advance our internal pointer
      def peek_slice(new_length, offset_adjustment=nil)
        offset_adjustment ||= 0

        self.class.new(@stream, 
                        startpos: (@startpos + @cur_offset + offset_adjustment), 
                        read_length: new_length
                      )
      end

      # How many remaining bytes are there
      def remaining
        size - tell
      end

      # Do we have any remaining bytes?
      def remaining?(len_to_check=1)
        remaining >= len_to_check
      end

      # Reset the position pointer back to the start
      def rewind
        @cur_offset = 0
      end

      def read(length=nil)

        original_pos = stell
        read_size = (length || size)

        if remaining - read_size < 0
          raise StreamOverrunError.new(read_size, remaining, original_pos)
        end

        @stream.seek(@startpos + @cur_offset, IO::SEEK_SET)
        resp = @stream.read(length)
        @cur_offset += read_size

        return resp
      rescue => e
        raise
      ensure
        # put the stream back
        # TODO: possibly remove this, it just makes it slower
        @stream.seek(original_pos, IO::SEEK_SET)
      end

      # Returns data without advancing the offset pointer
      def peek(length=nil)
        original_pos = stell
        read_size = (length || size)

        if remaining - read_size < 0
          raise StreamOverrunError.new(read_size, remaining, original_pos)
        end

        @stream.seek(@startpos + @cur_offset, IO::SEEK_SET)
        resp = @stream.read(length)

        return resp
      rescue => e
        raise
      ensure
        @stream.seek(original_pos, IO::SEEK_SET)
      end

      # Seek to a specific position, or relative
      def seek(seek_len, whence=IO::SEEK_CUR)
        raise ArgumentError.new("Position must be an integer") if seek_len.nil?

        case whence
        when IO::SEEK_SET, :SET
          proposal = seek_len
        when IO::SEEK_CUR, :CUR
          proposal = @cur_offset + seek_len
        when IO::SEEK_END, :END
          proposal = @stopper + seek_len # This will actually be a +(-999)
        else
          raise ArgumentError.new("whence must be :SET, :CUR, :END")
        end

        if valid_position?(proposal)
          @cur_offset = proposal
        else
          raise InvalidPositionError.new(proposal)
        end
        return true
      end

      # Is this actually a valid position?
      def valid_position?(proposal)
        proposal.abs <= size
      end

      def eof?
        remaining <= 0
      end

      # Position in our current high level stream
      def tell
        @cur_offset
      end
      alias_method :pos, :tell

      # Position on the underlying stream
      def stell
        @stream.tell
      end

      def total_size
        stopper - @startpos
      end
      alias_method :size, :total_size

      # Reads a null terminated string off the stream
      def read_string(length, encoding: "UTF-8", packfmt: "Z*")
        if length > 0
          res = read_single(packfmt, length).force_encoding(encoding).encode(encoding)
          track res
        else
          raise InvalidLengthError.new(length)
        end
      end

      # 8 bit boolean
      def read_bool
        res = read_single("C", 1)

        if res != 0 && res != 1
          raise InvalidBooleanValueError.new(res, (tell - 1))
        end

        track(res != 0)
      end
      alias_method :read_bool8, :read_bool

      # 8 Bits
      def read_int8
        track read_single("c", 1)
      end
      def read_uint8
        track read_single("C", 1)
      end
      def read_byte
        track read_single("c", 1)
      end

      # 16 Bits
      def read_uint16
        track read_single("S<", 2)
      end
      def read_uint16be
        track read_single("S>", 2)
      end
      alias_method :read_uint16le, :read_uint16

      def read_int16
        track read_single("s<", 2)
      end
      def read_int16be
        track read_single("s>", 2)
      end
      alias_method :read_int16le, :read_int16

      # 32 bits
      def read_int32
        track read_single("l<", 4)
      end
      def read_int32be
        track read_single("l>", 4)
      end
      alias_method :read_int32le, :read_int32

      def read_uint32
        track read_single("L<", 4)
      end
      def read_uint32be
        track read_single("L>", 4)
      end
      alias_method :read_uint32le, :read_uint32

      
      # 64 bits
      def read_int64
        track read_single("q<", 8)
      end
      def read_int64be
        track read_single("q>", 8)
      end
      alias_method :read_int64le, :read_int64

      def read_uint64
        track read_single("Q<", 8)
      end
      def read_uint64be
        track read_single("Q>", 8)
      end
      alias_method :read_uint64le, :read_uint64

      # 4 byte floats
      def read_float
        res = read_single("e", 4)
        if res.nan?
          raise InvalidFloatValueError.new(tell - 4)
        end
        track res
      end
      def read_floatbe
        res = read_single("g", 4)
        if res.nan?
          raise InvalidFloatValueError.new(tell - 4)
        end
        track res
      end
      alias_method :read_floatle, :read_float


      # 8 byte double
      def read_double
        res = read_single("E", 8)
        if res.nan?
          raise InvalidFloatValueError.new(tell - 8)
        end
        track res
      end
      def read_doublebe
        res = read_single("G", 8)
        if res.nan?
          raise InvalidFloatValueError.new(tell - 8)
        end
        track res
      end
      alias_method :read_doublele, :read_double


      def read_binary(len)
        track { sprintf("READ_BINARY(%d+%d = %d)", tell, len, (tell+len)) }
        read(len)
      end

      def read_hash(len)
        track read_single("H*", len)
      end

      def read_single(fmt, bytes = 4)
        read(bytes).unpack1(fmt)
      end

      def read_unpack(bytes, fmt)
        read(bytes).unpack(fmt)
      end

      # Dump entire stream to a file (for debugging)
      def dump(filename)
        # return nil unless $TESTING
        @stream.seek(@startpos, IO::SEEK_SET)
        File.open(filename, "wb") do |f|
          f.write(@stream.read(@stopper - @startpos))
        end
      end

      ##### MISC

      def method_missing(meth_name, *args, &block)
        meth = "read_#{meth_name}".to_sym
        if respond_to?(meth)
          public_send(meth, *args, &block)
        else
          super
        end
      end
    end
  end
end
