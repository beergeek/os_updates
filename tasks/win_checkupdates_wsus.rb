#!/opt/puppetlabs/puppet/bin/ruby
require 'open3'
require 'json'
require 'puppet'

params = JSON.parse(STDIN.read)

begin
  if ! Dir.exists?('C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate')
    case params['module_source']
    when 'puppet'
      Puppet.initialize_settings
      @server = Puppet.settings['server']
      x = ::Puppet::Resource.new('file', 'C:\Windows\temp\PSWindowsUpdate.zip', parameters: { ensure: 'file', source: "puppet://#{@server}/os_updates/PSWindowsUpdate.zip"})
      _result, _report = ::Puppet::Resource.indirection.save(x)
      if _result != 0
        puts 'Failed to upload PSWindowsUpdate Module'
        exit -1
      end
    when 'PS Gallery'
      download_cmd = '[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; $webClient = New-Object System.Net.WebClient; $webClient.DownloadFile("https://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc/file/41459/47/PSWindowsUpdate.zip","C:\Windows\temp\PSWindowsUpdate.zip")'
      _stdout, _stderr, _status = Opens.capture3(download_cmd)
      if _status != 0
        puts 'Failed to download ZIP file'
        exit -1
      end
    when 'URL'
      if params['module_url'].nil? || params['module_url'].empty?
        puts '`module_url` is required if URL method of retrieving the PSWindowsUpdate module is selected' 
        exit -1
      else
        download_cmd = "[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; $webClient = New-Object System.Net.WebClient; $webClient.DownloadFile('#{params['module_url']}','C:\\Windows\\temp\\PSWindowsUpdate.zip')"
        _stdout, _stderr, _status = Opens.capture3(download_cmd)
        if _status != 0
          puts 'Failed to download ZIP file'
          exit -1
        end
      end
    end
    unzip_cmd = 'powershell -c "Expand-Archive -LiteralPath C:\Windows\temp\PSWindowsUpdate.zip -DestinationPath C:\Windows\System32\WindowsPowerShell\v1.0\Modules"'
    _stdout, _stderr, _status = Opens.capture3(unzip_cmd)
    if _status != 0
      puts 'Failed to uncompress PSWindowsUpdate.zip'
      exit -1
    end
  end
  cmd_string = 'powershell -command "Import-Module PSWindowsUpdate; Get-WUList -WindowsUpdate | Format-List -Property KB,Size,Title"'
  stdout, stderr, status = Open3.capture3(cmd_string)
  raise "Output not recognised: #{stdout}", stderr if status != 0
  puts stdout.strip
  exit 0
rescue Exception => e
  puts "There was a problem #{e}"
end