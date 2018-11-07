#!/opt/puppetlabs/puppet/bin/ruby
require 'open3'
require 'json'

params = JSON.parse(STDIN.read)

def ensure_yumversion
  cmd_string = 'puppet resource package yum-plugin-versionlock ensure=present'
  _stdout, _stderr, status = Open3.capture3(cmd_string)
  raise 'Could not install `yum-plugin-versionlock`' unless status.zero?
rescue => e
  raise "Could not install `yum-plugin-versionlock`: #{e.message}"
end

begin
  ensure_yumversion
  cmd_string = "yum versionlock #{params['package_name']}"
  _stdout, _stderr, status = Open3.capture3(cmd_string)
  puts 'Could not pin package(s)' unless status.zero?
  list_string = 'yum versionlock list'
  stdout, _stderr, status = Open3.capture3(list_string)
  puts stdout unless status != 0
rescue => e
  raise "Could pin package(s): #{e.message}"
end
