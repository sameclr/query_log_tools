
require 'open3'

module Shell
  # Exeucte command in the shell
  def self.cmd(command)
    stdout, stderr, status = Open3.capture3(command)
    status.exitstatus == 0 or fail "command failed - '#{stderr}'"
    stdout.split("\n").map { |s| s.sub(/\s+$/, "") }
  end

  # List files in directory dir matching pattern
  def self.cmd_ls(dir, pattern)
    command = "find #{dir} -maxdepth 1 -type f -name '#{pattern}'"
    cmd(command).sort
  end

  # Execute command through ssh using the given connection string. A 
  # connection string is on the form 'username@host'
  def self.ssh(connection, command)
    stdout, stderr, status = Open3.capture3("ssh #{connection} '#{command}'")
    status.exitstatus == 0 or fail "ssh failed - '#{stderr}'"
    stdout.split("\n").map { |s| s.sub(/\s+$/, "") }
  end

  # List files in directory dir matching pattern through ssh using the given 
  # connection string
  def self.ssh_ls(connection, dir, pattern)
    command = "find #{dir} -maxdepth 1 -type f -name '\\''#{pattern}'\\''"
    ssh(connection, command).sort
  end

  # Copy remote file to local directory through ssh using the given 
  # connection string
  def self.scp(connection, remote_file, local_dir)
    local_file = "#{local_dir}/#{remote_file}"
    local_part_file = "#{local_file}.part"
    cmd("rm -f #{local_dir}/*.part")
    stdout, stderr, status = 
        Open3.capture3("scp #{connection}:./#{remote_file} #{local_part_file}")
    status.exitstatus == 0 or fail "ssh failed - '#{stderr}'"
    cmd("mv #{local_part_file} #{local_file}")
  end
end
