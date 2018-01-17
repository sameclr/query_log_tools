require 'digest'

module QueryLogTools
  class Entry < LogTools::Entry
    attr_reader :operation, :backtrace

    def initialize(timestamp, operation, duration, sql, backtrace)
      super(timestamp, duration, sql)
      @operation, @backtrace = operation, backtrace
    end

    def cached?() operation == "[cached]" end

    def write
      print "#{timestamp.strftime("%F %T %Z")} #{operation} (#{duration}ms)\n"
      print "  #{sql}\n"
      print "  ↳ #{backtrace.first}\n"
      backtrace.drop(1).each { |l| print "    #{l}\n" }
      puts
    end
  end
end

