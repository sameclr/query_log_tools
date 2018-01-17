
require 'log_tools/error'

require 'log_tools/mysql_log'
require 'log_tools/mysql_log_entry'

module MysqlLogTools
  def self.list(filename, format = :raw)
    log = Log.parse(filename)
    log.render_format(format)
  end

  def self.list_queries(filename)
    log = Log.parse(filename)
    log.entries.each { |e| print e.sql, ";\n" }
  end
end





