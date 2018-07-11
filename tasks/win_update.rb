#!/opt/puppetlabs/puppet/bin/ruby
require 'open3'
require 'json'
require 'win32/registry'

params = JSON.parse(STDIN.read)

def check_ps_module
  begin
    # Determine if the PSWindowsUpdate module is installed on disk and retrieve if it is not
    # Get registry setting for Powershell module directory
    reg_key = Win32::Registry::HKEY_LOCAL_MACHINE.open('System\CurrentControlSet\Control\Session Manager\Environment')
    module_path = (reg_key['PSModulePath']).split(';') || nil
    if module_path.nil? || module_path.empty?
      puts 'No module path for Powershell was found in the registry'
      exit -1
    end
    # Determine if the PSWindowsUpdate module is installed on disk and retrieve if it is not
    if ! Dir.exists?("#{module_path[0]}\\PSWindowsUpdate")
      case params['module_source']
      when 'PSGallery'
        url = 'https://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc/file/41459/47/PSWindowsUpdate.zip'
      when 'URL'
        if params['module_url'].nil? || params['module_url'].empty?
          puts '`module_url` is required if URL method of retrieving the PSWindowsUpdate module is selected'
          exit -1
        else
          url = params['module_url']
        end
      end
      download_cmd = "powershell -command \"[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; $webClient = New-Object System.Net.WebClient; $webClient.DownloadFile('#{url}','#{ENV['TEMP']}\\PSWindowsUpdate.zip')\""
      _stdout, _stderr, _status = Open3.capture3(download_cmd)
      if _status != 0
        puts 'Failed to download ZIP file'
        exit -1
      end
      # Unzip the file
      unzip_cmd = "powershell -command \"Expand-Archive -LiteralPath '#{ENV['TEMP']}\\PSWindowsUpdate.zip' -DestinationPath '#{module_path[0]}'\""
      _stdout, _stderr, _status = Open3.capture3(unzip_cmd)
      if _status != 0
        puts "Failed to uncompress PSWindowsUpdate.zip #{_stdout}"
        exit -1
      end
    end
  rescue StandardError => e
    raise Error, "Experienced an error: #{e.message}"
    exit -1
  end
end

begin
  # Find if we are using WSUS or Windows Update
  manager_cmd = "powershell -command \"Import-Module PSWindowsUpdate; Get-WUServiceManager | Where-Object {$_.IsManaged -eq 'true'} | foreach {$_.ServiceID}\""
  _stdout, _stderr, _status = Open3.capture3(manager_cmd)
  raise "Cannot get Windows Update configurations ", _stderr if _status != 0
  # Determine which service is enable can use that to apply patches and updates
  if params['allow_reboot'] == false {
    _allow_reboot = '-IgnoreReboot'
  }
  if _stdout
    case _stdout.strip
    when '3da21691-e39d-4da6-8a4b-b43877bcb1b7'
      cmd_string = "powershell -command \"Import-Module PSWindowsUpdate; Get-WUInstall -AcceptAll #{_allow_reboot}\""
    when '9482f4b4-e343-43b6-b170-9a65bc822c77'
      cmd_string = "powershell -command \"Import-Module PSWindowsUpdate; Get-WUInstall -WindowsUpdate -AcceptAll #{_allow_reboot}\""
    when '7971f918-a847-4430-9279-4a52d1efe18d'
      cmd_string = "powershell -command \"Import-Module PSWindowsUpdate; Get-WUInstall -MicrosoftUpdate -AcceptAll #{_allow_reboot}\""
    else
      puts 'No Update Services configured'
      exit 0
    end
    # run the relevant command
    stdout, stderr, status = Open3.capture3(cmd_string)
    if status == 0
      puts 'Patches applied'
      exit 0
    else
      puts 'Could not apply patch'
      exit -1
    end
  end
rescue StandardError => e
  raise Error,  "There was a problem #{e}"
  exit -1
end