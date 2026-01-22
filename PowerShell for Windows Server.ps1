# PowerShell for Windows Server 2019 and later

# This script configures a Windows Server with essential settings and features.
# It includes setting the timezone, enabling RDP, installing necessary features,
# and configuring firewall rules.

# Set Timezone
Set-TimeZone -Id "Pacific Standard Time"

# Enable Remote Desktop
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" 

# Install Necessary Features
Install-WindowsFeature -Name Web-Server, Web-Mgmt-Tools, RSAT-AD-PowerShell, Hyper-V -IncludeManagementTools

# Configure Firewall Rules
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

# Set PowerShell Execution Policy   
Set-ExecutionPolicy RemoteSigned -Force

# Restart the server to apply changes
Restart-Computer -Force

# End of Script

# Add Active Directory Domain Services Role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment
# Promote the server to a domain controller (uncomment and modify the parameters as needed)
# Install-ADDSForest -DomainName "example.com" -SafeModeAdministratorPassword (ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force) -InstallDNS   

# Configure Windows Update Settings
Install-WindowsFeature -Name UpdateServices, UpdateServices-UI
# Configure automatic updates (uncomment and modify as needed)
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 0
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 4
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "ScheduledInstallDay" -Value 0
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "ScheduledInstallTime" -Value 3

# Add Web Server (IIS) Role with Additional Features
Install-WindowsFeature -Name Web-Server, Web-Common-Http, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Static-Content, Web-Health, Web-Http-Logging, Web-Log-Libraries, Web-Request-Monitor, Web-Performance, Web-Stat-Compression, Web-Security, Web-Filtering, Web-Basic-Auth, Web-Windows-Auth, Web-App-Dev, Web-Net-Ext, Web-Net-Ext45, Web-Asp-Net, Web-Asp-Net45, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Mgmt-Tools, Web-Mgmt-Console -IncludeManagementTools    
# Configure IIS Default Website (uncomment and modify as needed)
# Set-ItemProperty -Path "IIS:\Sites\Default Web Site" -Name "PhysicalPath" -Value "C:\inetpub\wwwroot"
# Restart IIS to apply changes
# Restart-Service W3SVC

# Configure Network Settings
# Set a static IP address (uncomment and modify the parameters as needed)
# New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "192.168.1.100" -PrefixLength 24 -DefaultGateway "192.168.1.1" 
# Set DNS servers
# Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("8.8.8.8", "8.8.4.4")
# End of Additional Configurations

# Additional Configurations for Windows Server 2019 and later
# Note: Uncomment and modify the parameters as needed before running the script.    
# Configure Windows Defender Firewall to allow specific inbound traffic
New-NetFirewallRule -DisplayName "Allow SMB" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow
New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow

# Enable Windows Defender Antivirus
Install-WindowsFeature -Name Windows-Defender-Features  
Set-MpPreference -DisableRealtimeMonitoring $false

# Schedule a daily quick scan at 2 AM
$Action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-Command `"Start-MpScan -ScanType QuickScan`""
$Trigger = New-ScheduledTaskTrigger -Daily -At 2am  
Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "DailyQuickScan" -Description "Performs a daily quick scan with Windows Defender"    

# Update the server with the latest patches
Install-WindowsUpdate -AcceptAll -AutoReboot
# Note: You may need to install the PSWindowsUpdate module first using:
# Install-Module -Name PSWindowsUpdate -Force

# Backup Important System Settings (uncomment and modify as needed)
# Export-WindowsDriver -Online -Destination "C:\DriverBackup"
# Export-StartLayout -Path "C:\StartLayout.xml" -As XML
# End of Script

# Active Directory Users and Computer Management
Install-WindowsFeature -Name RSAT-AD-Tools
Import-Module ActiveDirectory
# Open Active Directory Users and Computers (uncomment to run)
dsa.msc

# Add new user to Active Directory
New-ADUser -Name "John Doe" -GivenName "John" -Surname "Doe" -SamAccountName "jdoe" -UserPrincipalName "jdoe@example.com" -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) -Enabled $true

# Remove user from Active Directory
Remove-ADUser -Identity "jdoe"

# Disable user account
Disable-ADAccount -Identity "jdoe"

# Enable user account
Enable-ADAccount -Identity "jdoe"

# Reset user password
Set-ADAccountPassword -Identity "jdoe" -NewPassword (ConvertTo-SecureString "N3wP@ssw0rd!" -AsPlainText -Force)

# Reset user password at next logon
Set-ADUser -Identity "jdoe" -ChangePasswordAtLogon $true

# Reset user password expiration
Set-ADUser -Identity "jdoe" -PasswordNeverExpires $false

############################################################################

# Check all open ports on the server
Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" } | Select-Object LocalAddress, LocalPort, State, OwningProcess

# Check all closed ports on the server
$allPorts = 1..65535
$openPorts = (Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" }).LocalPort
$closedPorts = $allPorts | Where-Object { $openPorts -notcontains $_ }
$closedPorts

# Check firewall rules
Get-NetFirewallRule | Select-Object DisplayName, Direction, Action, Enabled

# Firewall status
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
