require 'log_tools/entry'

module MysqlLogTools
  class Entry < LogTools::Entry
    attr_reader :lock_time, :rows_sent, :rows_examined

    def initialize(timestamp, duration, sql, lock_time, rows_sent, rows_examined)
      super(timestamp, duration, sql)
      @lock_time, @rows_sent, @rows_examined = lock_time, rows_sent, rows_examined
    end

    def render_format(format = :raw)
      print format_sql(format), "\n"
      print "   Timestamp: #{timestamp.strftime("%F %T %Z")}\n"
      print "   Duration : #{duration}ms\n" # TODO Flexible time
      print "   Lock time: #{lock_time}ms\n"
      print "   Rows examined: #{rows_examined}\n"
      print "   Rows sent    : #{rows_sent}\n"
    end
  end
end
