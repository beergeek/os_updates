#!/opt/puppetlabs/puppet/bin/ruby
require 'open3'
require 'json'

params = JSON.parse(STDIN.read)

begin
  # Determine if the PSWindowsUpdate module is installed on disk and retrieve if it is not
  if ! Dir.exists?('C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate')
    case params['module_source']
    when 'PS Gallery'
      url = 'https://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc/file/41459/47/PSWindowsUpdate.zip'
    when 'URL'
      if params['module_url'].nil? || params['module_url'].empty?
        puts '`module_url` is required if URL method of retrieving the PSWindowsUpdate module is selected'
        exit -1
      else
        url = params['module_url']
      end
    end
    download_cmd = "[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; $webClient = New-Object System.Net.WebClient; $webClient.DownloadFile('#{url}','C:\\Windows\\temp\\PSWindowsUpdate.zip')"
    _stdout, _stderr, _status = Opens.capture3(download_cmd)
    if _status != 0
      puts 'Failed to download ZIP file'
      exit -1
    end
    # Unzip the file
    unzip_cmd = 'powershell -c "Expand-Archive -LiteralPath C:\Windows\temp\PSWindowsUpdate.zip -DestinationPath C:\Windows\System32\WindowsPowerShell\v1.0\Modules"'
    _stdout, _stderr, _status = Opens.capture3(unzip_cmd)
    if _status != 0
      puts 'Failed to uncompress PSWindowsUpdate.zip'
      exit -1
    end
  end
  # Find if we are using WSUS or Windows Update
  manager_cmd = "powershell -command \"Import-Module PSWindowsUpdate; Get-WUServiceManager | Where-Object {$_.IsManaged -eq 'true'} | foreach {$_.ServiceID}\""
  _stdout, _stderr, _status = Open3.capture3(manager_cmd)
  raise "Cannot get Windows Update configurations ", _stderr if _status != 0
  # Determine which service is enable can use that to check for patches and updates
  if _stdout
    case _stdout.strip
    when '3da21691-e39d-4da6-8a4b-b43877bcb1b7'
      cmd_string = 'powershell -command "Import-Module PSWindowsUpdate; Get-WUList | Format-List -Property KB,Size,Title"'
    when '9482f4b4-e343-43b6-b170-9a65bc822c77'
      cmd_string = 'powershell -command "Import-Module PSWindowsUpdate; Get-WUList -WindowsUpdate | Format-List -Property KB,Size,Title"'
    when '7971f918-a847-4430-9279-4a52d1efe18d'
      cmd_string = 'powershell -command "Import-Module PSWindowsUpdate; Get-WUList -MicrosoftUpdate | Format-List -Property KB,Size,Title"'
    else
      puts 'No Update Services configured'
      exit 0
    end
    # run the relevant command
    stdout, stderr, status = Open3.capture3(cmd_string)
    if stdout and !stdout.nil? and !stdout.empty?
      puts stdout.strip
    else
      puts "No patches or updates found"
    end
    exit 0
  end
rescue
  puts "There was a problem"
end