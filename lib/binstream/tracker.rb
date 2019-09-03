# frozen_string_literal: true
module Binstream
  class Tracker
    include Singleton

    def initialize
      @tracking_buffer = []
      @enabled = false
    end

    def buffer
      @tracking_buffer
    end

    def enabled=(bool)
      @enabled = !!bool
    end

    def enabled?
      @enabled
    end

    def clear
      @tracking_buffer.clear
    end

    def track(message = nil, &block)

      value = if message.nil? && block_given?
                yield
              else
                message
              end

      if enabled?
        @tracking_buffer << value
      end

      return value

    end

    def print_debug_buffer(options={})
      return unless enabled?
      STDERR.puts ""
      STDERR.puts "DEBUG BUFFER:"
      debug_str = @tracking_buffer.map do |item|
        if item.nil?
          "\\x00"
        elsif item == :newline
          "\n\n"
        elsif item == :break
          "\n\t"
        else
          item.inspect
        end
      end.join(", ")
  
      STDERR.puts debug_str
      STDERR.puts ""
    end
  end
end
