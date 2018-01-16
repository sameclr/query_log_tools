
PROGRAM=File.basename($0)

# Not usable in combination with Thor
#def error(*msg)
# $stderr.print "#{PROGRAM}: #{msg.join(' ')}\n"
# $stderr.print "Usage: #{USAGE}\n"
# exit 1
#end

def fail(*msg)
  $stderr.print "#{PROGRAM}: #{msg.join(' ')}\n"
  exit 1
end

