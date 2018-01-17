require 'yaml'

require 'active_support/core_ext/module/delegation'

module MysqlLogTools
  class KnownEntry # Quacks like an Entry
    attr_reader :seen # Array of [timestamp, duration] in increasing order
    attr_reader :last_entry # Last seen entry
    attr_reader :min_duration, :max_duration

    delegate :timestamp, :duration, :lock_time, :rows_sent, :rows_examined,
        :sql, :short_sql, :abstract_sql, :format_sql, :abstract_fingerprint, 
        to: :last_entry

    def initialize(entry)
      @seen = [[entry.timestamp, entry.duration]]
      @last_entry = entry
      @min_duration = @max_duration = @sum_duration = entry.duration
    end

    def avg_duration() (@sum_duration / seen.size).round(1) end

    def add_entry(entry) # FIXME Guard against duplicated entries
      @seen << [entry.timestamp, entry.duration]
      @last_entry = entry
      @max_duration = [@max_duration, entry.duration].max
      @min_duration = [@min_duration, entry.duration].min
      @sum_duration += entry.duration
    end

    def freq_day() end
    def freq_week() end
    def freq_month() end
    def freq_quarter() end

    def purge() end

    def render_format(format = :raw)
      print format_sql(format), "\n"
      print "   Average Duration: #{avg_duration}ms ",
            "(max: #{max_duration}ms, min: #{min_duration}ms)\n" # TODO: Only if more than one entry
      print "   Seen #{seen.size} times in total\n"
      print "      # times today\n"
      print "      # times the last week\n"
      print "      # times the last month\n"
      print "      # times the last quarter\n"
      print "   Last seen: #{timestamp.strftime("%F %T %Z")}\n"
      print "      Duration : #{duration}ms\n"
      print "      Lock time: #{lock_time}ms\n"
      print "      Rows examined: #{rows_examined}\n"
      print "      Rows sent    : #{rows_sent}\n"
    end
  end

  class KnownLog
    attr_reader :entries

    def initialize()
      @entries = []
    end

    def self.load() 
      YAML.load_file("data.yaml")
    end

    def save() 
      File.open("data.yaml", "w") { |f| f.write(to_yaml) }
    end

    def entries_by_abstract_fingerprint
      @entries_by_abstract_fingerprint ||= 
          @entries.map { |e| [e.abstract_fingerprint, e] }.to_h
    end

    def key?(abstract_fingerprint)
      entries_by_abstract_fingerprint.key?(abstract_fingerprint)
    end

    def [](abstract_fingerprint)
      entries_by_abstract_fingerprint[abstract_fingerprint]
    end

    def merge(mysql_log) 
      mysql_log.entries.each { |e|
        afp = e.abstract_fingerprint
        if key?(afp)
          self[afp].add_entry(e)
        else
          entries << KnownEntry.new(e)
          entries_by_abstract_fingerprint[afp] = entries.last
        end
      }
    end

    def consolidate(slow_query_log) end

    def report(format = :raw)
      @entries.each { |e| e.render_format(format); puts }
    end

    def report_new() end

  private
    # Prevent YAML from persisting @entries_by_abstract_fingerprint
    # FIXME: Doesn't work. Also: Doesn't matter as YAML is quite clever
#   def encode_with(coder)
#     coder['entries'] = @entries
#     self
#   end
  end
end












