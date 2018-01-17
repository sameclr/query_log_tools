
require 'log_tools/error'

require 'log_tools/mysql_log'
require 'log_tools/mysql_log_entry'

module MysqlLogTools
  def self.list_queries(filename, format = :raw)
    log = Log.parse(filename)
    log.render_format(format)
  end
end





