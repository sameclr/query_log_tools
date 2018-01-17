require 'time'

require 'query_log_tools/mysql_log_entry.rb'

module MysqlLogTools
  class LogParser
    def self.parse(file)
      timestamp, duration, lock_time, rows_sent, rows_examined = nil
      sql = []
      skipping = true
      r = []
      file.each { |l|
        l.chomp!.strip!
        case l
        when /^$/
          ;
        when /^set |use /i
          ;
        when /^(?:mysqld,|Tcp port:|Time )/
          ;
        when /^# Time: (\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d)\.\d+Z$/
          timestamp = Time.parse($1)
          skipping = false
        when /^# Query_time: ([\d.]+)\s+Lock_time: ([\d.]+)\s+Rows_sent: (\d+)\s+Rows_examined: (\d+)$/
          duration = 1000 * $1.to_f
          lock_time = 1000 * $2.to_f
          rows_sent = $3.to_i
          rows_examined = $4.to_i
        else
          if l.end_with?(";")
            sql << l.chop
            r << Entry.new(timestamp, duration, sql.join(" "), lock_time, rows_sent, rows_examined)
            sql = []
          end
        end
      }
      r
    end
  end
end
