require 'mysql2'
require 'yaml'

require 'query_log_tools/query_log_entry'
require 'query_log_tools/query_log_entry_group'
require 'query_log_tools/query_log'
require 'query_log_tools/query_log_parser'
require 'query_log_tools/query_log_summary'
require 'query_log_tools/version'

module QueryLogTools
  def query_log_summary(filename_or_nil)
    log = Log.new(filename_or_nil || $stdin)
    LogSummary.new(log).report
  end

  def query_log_queries(filename_or_nil, options)
    Log.new(filename_or_nil || $stdin).entries.each { |e|
      !e.cached? || options[:cached] or next
      print e.sql, "\n"
    }
  end

  def query_log_classes(filename_or_nil, options)
    h = Hash.new(0)
    Log.new(filename_or_nil || $stdin).entries.map(&:operation).each { |op|
      next if op !~ /^"(.*) Load"$/
      klass = op.sub(/\"(.*) Load"/, '\1')
      h[klass] += 1
    }
    if options[:counts]
      h.sort_by(&:last).reverse.each { |k, v|
        print v, " ", k, "\n"
      }
    else
      h.keys.sort.each { |k| puts k }
    end
  end

  def query_log_capture(logfile_or_nil)
    logfile_or_nil ||= "log/small_query.log"
    File.exist?(logfile) or error "ERROR: Can't find '#{logfile}'"
    system("tail -f #{logfile_or_nil} | sed -u '1,10d'")
  end

  def query_log_replay(filename, options)
    config_file = find_database_yml(options[:config])
    config = YAML.load_file(config_file)[options[:environment]] or
        error "ERROR: Can't load #{options[:environment]} environment " \
              "from #{config_file}"

    connection = Mysql2::Client.new({
        :host => options[:host] || config["host"],
        :username => options[:username] || config["username"],
        :password => options[:password] || config["password"],
        :database => options[:database] || config["database"]
    })

    print "# Logfile created on #{Time.now.strftime('%F %T %Z')} " \
          "against #{config["database"]}@#{config["host"]}\n\n"

    Log.new(filename || $stdin).entries.each { |e|
      next if e.cached?
      timestamp = Time.now.utc
      duration = time_sql(connection, e.sql, options[:"warm-up"])
      Entry.new(timestamp, e.operation, duration, e.sql, e.backtrace).write
    }
  end

private
  # Find path to database.yml. filename_or_nil is either a direct path to
  # database.yml, a path to the rails root directory, or nil. If nil, this 
  # method will search upwards in the dirctory hierarchy looking for a rails 
  # root
  def find_database_yml(filename_or_nil)
    if filename_or_nil
      if File.file?(filename_or_nil)
        return filename_or_nil
      elsif File.directory?(filename_or_nil)
        filename = "#{filename_or_nil}/config/database.yml"
        File.file?(filename) or 
            error "ERROR: '#{filename_or_nil}' is not a Rails root directory"
        return filename
      else
        error "ERROR: Can't read '#{filename_or_nil}'"
      end
    else
      path = Dir.pwd + "/"
      dirs = path.scan(/[^\/]*\//)
      while !dirs.empty?
        filename = dirs.join + "config/database.yml"
        return file if File.exist?(filename)
        dirs.pop
      end
      error "ERROR: Can't find database configuration file"
    end
  end

  def time_sql(connection, stmt, warm_up)
    d = []
    for i in (0..warm_up)
      t0 = Time.now
      result = connection.query(stmt)
      t1 = Time.now
      d << (1000.0 * (t1 - t0)).round(1)
    end
    d.min
  end
end


















