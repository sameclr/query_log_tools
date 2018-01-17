
module QueryLogTools
  class Log
    attr_reader :filename, :entries, :start_timestamp, :end_timestamp

    def initialize(filename_or_stdin)
      if filename_or_stdin == $stdin
        ifile = $stdin
        @filename = "/dev/stdin"
      else
        ifile = File.open(filename_or_stdin, "r")
        @filename = filename_or_stdin
      end
      @entries = []
      parse(ifile)
      @start_timestamp = @entries.first&.timestamp
      @end_timestamp = @entries.last&.timestamp
    end

    def job_duration() (1000.0 * (end_timestamp - start_timestamp)).round(1) end
    def sql_duration() @sql_duration ||= entries.sum(&:duration).round(1) end

  private
    def parse(ifile)
      found = false
      timestamp, operation, duration, sql, backtrace = nil
      ifile.each { |l|
        l.chomp!
        case l
        when /^\s*(?:#.*)?$/ # Emit on terminating empty line
          if found
            @entries << Entry.new(timestamp, operation, duration, sql, backtrace)
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
    end
  end
end
