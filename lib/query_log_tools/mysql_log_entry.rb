
module MySqlLogTools
  class Entry < LogTools::Entry
    attr_reader :lock_time, :rows_sent, :rows_examined

    def initialize(timestamp, duration, sql, lock_time, rows_sent, rows_examined)
      super(timestamp, duration, sql)
      @lock_time, @rows_sent, @rows_examined = lock_time, rows_sent, rows_examined
    end

    def report
      print "Timestamp: #{timestamp.strftime("%F %T %Z")}\n"
      print "Duration : #{duration}ms\n"
      print "Lock time: #{lock_time}ms\n"
      print "Rows examined: #{rows_examined}\n"
      print "Rows sent    : #{rows_sent}\n"
      print sql, "\n"
    end
  end
end
