#!/opt/puppetlabs/puppet/bin/ruby
require 'open3'
require 'json'

params = JSON.parse(STDIN.read)

def ensure_yumversion
  cmd_string = 'puppet resource package yum-plugin-versionlock ensure=present'
  stdout, _stderr, status = Open3.capture3(cmd_string)
  raise "Could not install `yum-plugin-versionlock`: #{e.message}" unless status == 0
rescue => e
  raise "Could not install `yum-plugin-versionlock`: #{e.message}"
end

begin
  ensure_yumversion()
  cmd_string = "yum versionlock #{params['package_name']}"
  stdout, _stderr, status = Open3.capture3(cmd_string)
  puts stdout unless status != 0
rescue => e
  raise "Could not update: #{e.message}"
end
