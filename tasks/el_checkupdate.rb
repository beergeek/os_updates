#!/opt/puppetlabs/puppet/bin/ruby
require 'open3'

begin
  cmd_string = 'yum check-update'
  stdout, _stderr, _status = Open3.capture3(cmd_string)
  puts stdout unless _status != 0
rescue => e
  raise "Could not check for updates: #{e}"
end
