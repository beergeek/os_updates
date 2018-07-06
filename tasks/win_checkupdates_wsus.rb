#!/opt/puppetlabs/puppet/bin/ruby
require 'open3'

begin
  cmd_string = 'powershell -command "Import-Module PSWindowsUpdate"'
  stdout, stderr, status = Open3.capture3(cmd_string)
  raise 'Output not recognised', stderr if status != 0
  cmd_string = 'powershell -command "Get-WUList -WindowsUpdate | Format-List -Property KB,Size,Title"'
  stdout, stderr, status = Open3.capture3(cmd_string)
  raise 'Output not recognised', stderr if status != 0
  puts stdout.strip
  exit 0
rescue
  puts 'Output not recognised'
end