require 'query_log_tools/log_parser'

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
      @entries = LogParser.parse(ifile)
      @start_timestamp = @entries.first&.timestamp
      @end_timestamp = @entries.last&.timestamp
    end

    def job_duration() (1000.0 * (end_timestamp - start_timestamp)).round(1) end
    def sql_duration() @sql_duration ||= entries.sum(&:duration).round(1) end
  end
end
