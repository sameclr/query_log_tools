
module LogTools
  class Entry
    DEFAULT_SHORT_SQL_LENGTH = 1024

    attr_reader :timestamp, :duration, :sql

    def initialize(timestamp, duration, sql)
      @timestamp, @duration, @sql = timestamp, duration, sql
    end

    # Return SQL in one of the following formats: :raw, :short, :abstract
    def format_sql(format = :raw, max_size = DEFAULT_SHORT_SQL_LENGTH)
      case format
      when :raw; sql
      when :short; short_sql(max_size)
      when :abstract; abstract_sql
      else
        raise "Illegal format: '#{format}'"
      end
    end

    def short_sql(max_size = DEFAULT_SHORT_SQL_LENGTH)
      if sql.size > size
        sql[0...max_size] +  + "... [#{sql.size} characters in total]"
      else
        sql
      end
    end

    def abstract_sql
      @abstract_sql ||= begin
        s = sql.dup

        # Protect special phrases
        s.gsub!(/'(Client|Shop)'/, 'STRING_\1')
        s.gsub!(/LIMIT 1/, 'LIMIT_1')
        s.gsub!(/`disabled` = (\d+)/, 'DISABLED_\1')
        s.gsub!(/`active` = (\d+)/, 'ACTIVE_\1')

        # Substitute
        s.gsub!("`", "") # Remove backticks
        s.gsub!(/([^']*)'[^']*'/, '\1?') # Strings
        s.gsub!(/\(-?\d+(\s*,\s*-?\d+)*\)/, "(?)") # IN clause
        s.gsub!(/\d\d\d\d-\d\d-\d\d/, "?") # Dates
        s.gsub!(/\b\d+\b/, "?") # Integers
        s.gsub!(/\s\s+/, " ") # Remove repeated spaces

        # Undo protection
        s.gsub!(/\bACTIVE_(\d+)\b/, 'active = \1')
        s.gsub!(/\bDISABLED_(\d+)\b/, 'disabled = \1')
        s.gsub!(/\bLIMIT_1\b/, 'LIMIT 1')
        s.gsub!(/\bSTRING_(\S+)\b/, "'\\1'")

        s
      end
    end

    def fingerprint
      @fingerprint ||= begin
        MD5.reset
        MD5 << sql
        MD5.hexdigest
      end
    end

    def abstract_fingerprint
      @abstract_fingerprint ||= begin
        MD5.reset
        MD5 << abstract_sql
        MD5.hexdigest
      end
    end

  private
    MD5 = Digest::MD5.new
  end
end

