require 'active_support/core_ext/module/delegation' # for #delegate

# TODO Rename LogReport
module QueryLogTools
  class LogSummary
    # Number of milliseconds before switching to present the time as
    # minutes/seconds instead of milliseconds
    TIME_FORMAT_THRESHOLD = 100_000 

    # Default number of items to include in top-lists
    TOP_LIST_LENGTH = 5

    delegate :filename, :entries, :start_timestamp, :end_timestamp, 
             :job_duration, :sql_duration, to: :@log

    # TODO Move to Log
    attr_reader :cached_entries, :repeated_entries, :abstract_entries, :singleton_entries

    def initialize(log)
      @log = log

      @cached_entries = []
      @repeated_entries = []
      @abstract_entries = []
      @singleton_entries = entries.dup

      cached = []
      @singleton_entries.reject! { |e| e.cached? and cached << e }
      @cached_entries = cached.group_by(&:fingerprint).values.map { |ea| EntryGroup.new(ea) }
      @singleton_entries = @singleton_entries.group_by(&:fingerprint).values.reject { |ea|
        ea.size > 1 and @repeated_entries << EntryGroup.new(ea)
      }.flatten
      @singleton_entries = @singleton_entries.group_by(&:abstract_fingerprint).values.reject { |ea|
        ea.size > 1 and @abstract_entries << EntryGroup.new(ea)
      }.flatten
    end

    def cached_duration() @cached_duration ||= cached_entries.sum(&:duration).round(1) end
    def repeated_duration() @repeated_duration ||= repeated_entries.sum(&:duration).round(1) end
    def abstract_duration() @abstract_duration ||= abstract_entries.sum(&:duration).round(1) end
    def singleton_duration() @singleton_duration ||= singleton_entries.sum(&:duration).round(1) end

    def cached_count() @cached_count ||= @cached_entries.sum(&:count) end
    def executed_count() entries.size - cached_count end
    def repeated_count() @repeated_count ||= repeated_entries.sum(&:count) end
    def abstract_count() @abstract_count ||= abstract_entries.sum(&:count) end
    def singleton_count() singleton_entries.size end

    def report(options = {})
      top_n = options[:top_n] || TOP_LIST_LENGTH
      format = options[:format] || :raw

      print_summary
#     print_cached_queries(top_n) if !cached_entries.empty?
      print_repeated_queries(top_n) if !repeated_entries.empty?
      print_abstract_queries(top_n) if !abstract_entries.empty?
      print_slow_queries(top_n, format)
    end

    def print_summary
      cw = entries.size.to_s.size # Count Width

      if job_duration >= TIME_FORMAT_THRESHOLD
        job_duration_s = ms2time(job_duration)
        sql_duration_s = "%#{job_duration_s.size}s" % ms2time(sql_duration)
      else
        job_duration_s = "%.1fms" % job_duration
        sql_duration_s = "%#{job_duration_s.size-2}.1fms" % sql_duration
      end

      print "Summary of #{filename}\n"
      print "   Start: #{start_timestamp}\n"
      print "   End  : #{end_timestamp}\n"
      print "   Job duration: #{job_duration_s}\n"
      print "   SQL duration: #{sql_duration_s} (#{pct(job_duration, sql_duration)})\n"
      puts
      print "   Total queries   : #{entries.size}\n"
      print "   Cached queries  : #{rir(cached_count, cw)}, #{cached_entries.size} unique\n"
      print "   Executed queries: #{rir(entries.size-cached_count, cw)}, ",
          "#{repeated_entries.size+abstract_entries.size+singleton_entries.size} unique\n"
      print "      Repeated     : #{rir(repeated_count, cw)}, ",
          "#{repeated_entries.size} unique ",
          "(#{repeated_duration}ms, #{pct(sql_duration, repeated_duration)} of SQL)\n"
      print "      Abstract     : #{rir(abstract_count, cw)}, ",
          "#{abstract_entries.size} unique ",
          "(#{abstract_duration}ms, #{pct(sql_duration, abstract_duration)} of SQL)\n"
      print "      Singleton    : #{rir(singleton_entries.size, cw)} ",
          "(#{singleton_duration}ms, #{pct(sql_duration, singleton_duration)} of SQL)\n"
      puts
    end

    def print_cached_queries(top_n)
      print "   Top-#{top_n} cached queries by frequency:\n"
      cached_entries.sort_by(&:count).reverse.first(top_n).each { |e|
        print "      #{e.count} times (#{e.duration}ms), #{e.sql}\n"
      }
      puts
    end

    def print_repeated_queries(top_n)
      print "   Top-#{top_n} repeated queries by frequency:\n"
      repeated_entries.sort_by(&:count).reverse.first(top_n).each { |e|
        print "      #{e.count} times (#{e.duration}ms) #{e.sql}\n"
      }
      puts
    end

    def print_abstract_queries(top_n)
      print "   Top-#{top_n} abstract queries by frequency:\n"
      abstract_entries.sort_by(&:count).reverse.first(top_n).each { |e|
        print "      #{e.count} times (#{e.duration}ms) #{e.abstract_sql}\n"
      }
      puts
    end

    def print_slow_queries(top_n, format)
      print "   Top-#{top_n} slow queries:\n"
      entries.sort_by(&:duration).reverse.first(top_n).each { |e|
        print "      #{e.duration}ms (#{pct(sql_duration, e.duration)}) "
        puts e.format_sql(format)
      }
      puts
    end

  private
    # Compute and render procent with a '%' suffix
    def pct(whole, part) (100 * part.to_f / whole).round(1).to_s + "%" end

    # Render integer right-adjusted in a w-sized field
    def rir(n, w) "%#{w}d" % n end 

    # Render time in milliseconds as duration in hours/mins/secs
    def ms2time(ms)
      s = (ms / 1000).round(0)
      hours, mins, secs = s / 3600, s / 60 % 60, s % 60
      if hours > 0
        "%d:%02d:%02d" % [hours, mins, secs]
      else
        "%d:%02d" % [mins, secs]
      end
    end
  end
end






