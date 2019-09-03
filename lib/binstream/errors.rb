module Binstream
  class Error < ::StandardError
  end

  # PARSER

  class ParseError < ::StandardError
  end

  class InvalidLengthError < ParseError
    def initialize(len)
      super("You must provide a length greater than 0")
    end
  end

  class StreamOverrunError < ParseError
    def initialize(length, remaining, position)
      super(sprintf("Overrun! Reading %d bytes (remaining=%d pos=%d)", length, remaining, position))
    end
  end

  class InvalidPositionError < ParseError
    def initialize(proposal)
      super(sprintf("Wanted to seek to %d!!", proposal))
    end
  end

  class InvalidBooleanValueError < ParseError
    def initialize(bad_value, position)
      super(sprintf("Expected boolean value of 1 or 0, but got %d (0x%02X) pos=%d", bad_value, bad_value, position))
    end
  end

  class InvalidFloatValueError < ParseError
    def initialize(position)
      super(sprintf("Expected float, but got NaN pos=%d", position))
    end
  end
end