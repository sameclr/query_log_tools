require 'time'

require 'log_tools/query_log_entry.rb'

module QueryLogTools
  class LogParser
    def self.parse(ifile)
      found = false
      timestamp, operation, duration, sql, backtrace = nil
      r = []
      ifile.each { |l|
        l.chomp!
        case l
        when /^\s*(?:#.*)?$/ # Emit on terminating empty line
          if found
            r << Entry.new(timestamp, operation, duration, sql, backtrace)
            found = false
          end
        when /^(\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d \S+) (.*?) \(([\d.]+)ms\)\s*$/
          timestamp = Time.parse($1)
          operation = $2
          duration = $3.to_f
          found = true
        when /^  ([a-zA-Z].*)$/
          sql = $1
        when /^  ↳ (\S.*)$/
          backtrace = [$1]
        when /^    (\S.*)$/
          backtrace << $1
        else
          $stderr.print "Unexpected line: '#{l}'\n"
          exit(1)
        end
      }
      r
    end
  end
end
