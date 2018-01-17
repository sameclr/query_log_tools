
require 'log_tools/error'
require 'log_tools/shell'

require 'log_tools/mysql_log'
require 'log_tools/mysql_log_entry'
require 'log_tools/mysql_known_log'

# TODO: Move to options or configuration 
MYSQL_HOST = "in26.samesystem.net"
MYSQL_USER = "deployer"
MYSQL_DIR = "."
MYSQL_CONNECTION = "#{MYSQL_USER}@#{MYSQL_HOST}"
LOG_PATTERN = "slow_query_log_*"
COMPRESSED_LOG_PATTERN = "#{LOG_PATTERN}.xz"

ROOT_DIR = "var"
INCOMING_DIR = "#{ROOT_DIR}/incoming"
READY_DIR = "#{ROOT_DIR}/ready"
DATA_DIR = "#{ROOT_DIR}/data"
ARCHIVE_DIR = "#{ROOT_DIR}/archive"

module MysqlLogTools
  def self.init
    Shell.cmd("mkdir -p #{INCOMING_DIR} #{READY_DIR} #{ARCHIVE_DIR} #{DATA_DIR}")
  end

  def self.fetch
    init
    print "Fetching...\n"
    remote_files = 
        Shell.ssh_ls(MYSQL_CONNECTION, MYSQL_DIR, COMPRESSED_LOG_PATTERN)
    # TODO: Filter already received files
    remote_files.each { |f| 
      print "Downloading #{f}\n"
      Shell.scp(MYSQL_CONNECTION, f, INCOMING_DIR)
    }

    Shell.cmd_ls(INCOMING_DIR, COMPRESSED_LOG_PATTERN).each { |src|
      dst = "#{READY_DIR}/#{File.basename(src, '.xz')}"
      Shell.cmd("xz -dkc #{src} >#{dst}")
      Shell.cmd("mv #{src} #{ARCHIVE_DIR}")
    }

    print "Remove remote files\n"
    print "TODO\n"
    # Shell.ssh(MYSQL_CONNECTION, "rm -f #{remote_files.join(' ')}")
  end

  def self.process(filename)
    init
    known = KnownLog.load
    log = Log.parse(filename)
    known.merge(log)
    known.save
    known.report(:abstract)
  end

  def self.list(filename, format = :raw)
    log = Log.parse(filename)
    log.render_format(format)
  end
end





