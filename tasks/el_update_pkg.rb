#!/opt/puppetlabs/puppet/bin/ruby
require 'open3'
require 'json'

params = JSON.parse(STDIN.read)

begin
  cmd_string = "yum update -y #{params['package_name']}"
  stdout, _stderr, status = Open3.capture3(cmd_string)
  puts stdout unless status != 0
rescue => e
  raise "Could not update: #{e.message}"
end
