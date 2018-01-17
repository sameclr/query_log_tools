require 'digest'

module QueryLogTools
  class Entry < LogTools::Entry
    attr_reader :operation, :backtrace

    def initialize(timestamp, operation, duration, sql, backtrace)
      super(timestamp, duration, sql)
      @operation, @backtrace = operation, backtrace
    end

    def cached?() operation == "[cached]" end
  end
end

