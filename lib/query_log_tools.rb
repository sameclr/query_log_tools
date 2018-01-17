require 'mysql2'
require 'yaml'

require 'log_tools/entry.rb'
require 'log_tools/error'
require 'log_tools/version'

require 'log_tools/query_log'
require 'log_tools/query_log_entry'
require 'log_tools/query_log_entry_group'
require 'log_tools/query_log_summary'

module QueryLogTools
  def self.report(filename, options = {})
    log = Log.new(filename)
    LogSummary.new(log).report(options)
  end

  def self.list(filename, incl_cached)
    Log.new(filename).entries.each { |e|
      !e.cached? || incl_cached or next
      e.render
      puts
    }
  end

  def self.list_queries(filename, options)
    Log.new(filename).entries.each { |e|
      !e.cached? || options[:cached] or next
      print e.sql, ";\n"
    }
  end

  def self.list_classes(filename, options)
    h = Hash.new(0)
    Log.new(filename).entries.map(&:operation).each { |op|
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

  def self.capture(logfile)
    File.exist?(logfile) or fail "Can't find '#{logfile}'"
    system("tail -f #{logfile_or_nil} | sed -u '1,10d'")
  end

  def self.replay(filename, options)
    config_file = find_database_yml(options[:config])
    config = YAML.load_file(config_file)[options[:environment]] or
        fail "Can't load #{options[:environment]} environment " \
             "from #{config_file}"

    connection = Mysql2::Client.new({
        :host => options[:host] || config["host"],
        :username => options[:username] || config["username"],
        :password => options[:password] || config["password"],
        :database => options[:database] || config["database"]
    })

    print "# Logfile created on #{Time.now.utc.strftime('%F %T %Z')} " \
          "against #{config["database"]}@#{config["host"]}\n\n"

    # FIXME Entry#render is missing
    Log.new(filename || $stdin).entries.each { |e|
      next if e.cached?
      timestamp = Time.now.utc
      duration = time_sql(connection, e.sql, options[:"warm-up"])
      Entry.new(timestamp, e.operation, duration, e.sql, e.backtrace).render
    }
  end

private
  # Find path to database.yml. filename_or_nil is either a direct path to
  # database.yml, a path to the rails root directory, or nil. If nil, 
  # find_database_yml will search upwards in the directory hierarchy looking 
  # for a rails root
  def self.find_database_yml(filename_or_nil)
    if filename_or_nil
      filename = filename_or_nil
      if File.file?(filename)
        return filename
      elsif File.directory?(filename)
        filename = "#{filename}/config/database.yml"
        File.file?(filename) or 
            fail "'#{filename}' is not a Rails root directory"
        return filename
      end
      fail "Can't read '#{filename}'"
    else
      path = Dir.pwd + "/"
      dirs = path.scan(/[^\/]*\//)
      while !dirs.empty?
        filename = dirs.join + "config/database.yml"
        return file if File.exist?(filename)
        dirs.pop
      end
      fail "Can't find database configuration file"
    end
  end

  def self.time_sql(connection, stmt, warm_up)
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

