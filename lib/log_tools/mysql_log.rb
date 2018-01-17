require 'time'

require 'log_tools/mysql_log_entry'

module MysqlLogTools
  class Log
    attr_reader :filename, :entries

    def initialize(filename)
      @filename, @entries = filename, []
      parse(filename)
    end

    def render_format(sql_format = :raw)
      entries.each { |e| e.render_format(sql_format); puts }
    end

  private
    def parse(filename)
      timestamp, duration, lock_time, rows_sent, rows_examined = nil
      sql = []
      File.open(filename, "r").each { |l|
        l.strip!
        case l
        when /^$/
          ;
        when /^(?:mysqld,|Tcp port:|Time )/ # Skip preamble
          ;
        when /^set |use /i # Skip set and use statements
          ;
        when /^# User@Host: /
          ;
        when /^# Time: (\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d)\.\d+Z$/
          timestamp = Time.parse($1).utc
        when /^# Query_time: ([\d.]+)\s+Lock_time: ([\d.]+)\s+Rows_sent: (\d+)\s+Rows_examined: (\d+)$/
          duration = (1000 * $1.to_f).round(1)
          lock_time = (1000 * $2.to_f).round(1)
          rows_sent = $3.to_i
          rows_examined = $4.to_i
        else
          if l.end_with?(";")
            sql << l.chop
            @entries << Entry.new(
                timestamp, duration, sql.join(" "), 
                lock_time, rows_sent, rows_examined)
            sql = []
          else
            sql << l
          end
        end
      }
    end
  end
end
