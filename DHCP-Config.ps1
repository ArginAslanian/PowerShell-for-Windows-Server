# Deploy DHCP - Windows Server 2022
# Server is domain joined and has static IP
# This script installs and configures the DHCP Server role on a Windows Server 2022 machine

# =========================
# VARIABLES 
# =========================
$DhcpServerFqdn   = "$env:COMPUTERNAME.$env:USERDNSDOMAIN"   # DHCP server FQDN (domain-joined)
$DhcpServerIP     = "10.0.1.11"                              # DHCP server IP
$ScopeName        = "LAN-10.0.1.0-24"                        # Friendly scope name
$ScopeId          = "10.0.1.0"                               # Scope network ID
$StartRange       = "10.0.1.55"                              # Start of DHCP pool
$EndRange         = "10.0.1.220"                             # End of DHCP pool
$SubnetMask       = "255.255.255.0"                          # Subnet mask
$Router           = "10.0.1.1"                               # Default gateway 
$DnsServers       = @("10.0.1.10")                           # DNS servers for clients 
$DnsDomain        = "argin.local"                            # DNS domain for clients
$LeaseDays        = 7                                        # Lease duration in days

# =========================

# Optional reservations (add/remove as needed)
# MAC format: 00-11-22-33-44-55
# $Reservations = @(
#   @{ Name="printer01"; IP="10.0.1.60"; MAC="AA-BB-CC-11-22-33" },
# )
# # =========================

# 1) Install DHCP Server role
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# 2) Add DHCP security groups
Add-DhcpServerSecurityGroup -DnsName $DhcpServerFqdn

# 3) Restart DHCP service to apply security groups
Restart-Service -Name DHCPServer

# 4) Authorize DHCP server in Active Directory
Add-DhcpServerInDC -DnsName $DhcpServerFqdn -IpAddress $DhcpServerIP # Authorizes the DHCP server in AD so it’s allowed to hand out leases.

# 5) Create a new DHCP scope
Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartRange -EndRange $EndRange -SubnetMask $SubnetMask -State Active

# 6) Set the lease duration for the scope
Set-DhcpServerv4Scope -ScopeId $ScopeId -LeaseDuration (New-TimeSpan -Days $LeaseDays)

# 7) Set default gateway (router) option for the scope
Set-DhcpServerv4OptionValue -ScopeId $ScopeId -Router $Router

# 8) Set DNS servers option for the scope
Set-DhcpServerv4OptionValue -ScopeId $ScopeId -DnsServer $DnsServers

# 9) Set DNS domain option for the scope
Set-DhcpServerv4OptionValue -ScopeId $ScopeId -DnsDomain $DnsDomain

# 10) Enable dynamic DNS updates for the scope
Set-DhcpServerv4DnsSetting -ScopeId $ScopeId -DynamicUpdates Always -DeleteDnsRROnLeaseExpiry $true

# 11) (Optional) Add reservations
# foreach ($res in $Reservations) {
#   Add-DhcpServerv4Reservation -ScopeId $ScopeId -IPAddress $res.IP -ClientId $res.MAC -Name $res.Name
# }

# 12) Ensure firewall rules for DHCP are enabled
Enable-NetFirewallRule -DisplayGroup "DHCP Server"

# =========================
# VERIFICATION / TESTS
# =========================
# Confirm DHCP server status
Get-Service DHCPServer | Select-Object Status, Name, DisplayName

# List DHCP scopes to verify creation
Get-DhcpServerv4Scope | Select-Object ScopeId, Name, StartRange, EndRange, SubnetMask, State, LeaseDuration

# Show DHCP server options for the scope
Get-DhcpServerv4OptionValue -ScopeId $ScopeId

# List reservations to verify creation
Get-DhcpServerv4Reservation -ScopeId $ScopeId | Select-Object IPAddress, ClientId, Name

# On a client machine, run:
# ipconfig /release
# ipconfig /renew
# ipconfig /all
# To confirm the client receives an IP from the DHCP server with correct options.
# =========================
# To deploy this script:
# 1) Save as DHCP-Config.ps1
# 2) Run in PowerShell as Administrator on the DHCP server
# =========================