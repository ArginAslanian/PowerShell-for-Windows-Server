# Deploying DNS - Windows Server 2022
# This script installs and configures the DNS Server role on a Windows Server 2022 machine
# Example zone: argin.local
# Server IP: 10.0.1.10
# Default Gateway: 10.0.1.1
# Forwarders: 1.1.1.1 and 8.8.8.8

# =========================
# VARIABLES 
# =========================
$ZoneName     = "argin.local"               # Internal DNS zone name
$DnsServerIP  = "10.0.1.10"                 # This server's static IP
$Gateway      = "10.0.1.1"                  # Default gateway
$IfAlias      = "Ethernet"                  # NIC name (Get-NetAdapter to confirm)
$Forwarders   = @("1.1.1.1","8.8.8.8")      # DNS forwarders (public or upstream)
$HostAName    = "dns01"                     # Hostname for A record in your zone
$HostAIP      = $DnsServerIP                # A record IP address

# =========================

# 1) Show adapter info so you can confirm NIC name and current settings
Get-NetAdapter | Select-Object Name, Status, LinkSpeed

# 2) Set static IP address, subnet mask, and default gateway
New-NetIPAddress -InterfaceAlias $IfAlias -IPAddress $DnsServerIP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias $IfAlias -ServerAddresses $DnsServerIP
Write-Host "Static IP address set to $DnsServerIP with gateway $Gateway on interface $IfAlias"

# 3) Install DNS Server role
Install-WindowsFeature -Name DNS -IncludeManagementTools
Write-Host "DNS Server role installed."

# 4) Confirm the DNS service is running
Get-Service DNS | Select-Object Status, Name, DisplayName

# 5) Configure DNS forwarders
Set-DnsServerForwarder -IPAddress $Forwarders -PassThru # Sets upstream DNS servers that this DNS server will forward unknown queries to.

# 6) Create a primary forward lookup zone
Add-DnsServerPrimaryZone -Name $ZoneName -ZoneFile "$ZoneName.dns" -DynamicUpdate NonsecureAndSecure

# 7) Create a matching reverse lookup zone
$ReverseZone = ($DnsServerIP -split '\.')[0..2] -join '.' + ".in-addr.arpa"
Add-DnsServerPrimaryZone -NetworkId ($DnsServerIP -split '\.')[0..2] -ZoneFile "$ReverseZone.dns" -DynamicUpdate NonsecureAndSecure

# 8) Add an A record for the DNS server
Add-DnsServerResourceRecordA -Name $HostAName -ZoneName $ZoneName -IPv4Address $HostAIP -TimeToLive 01:00:00
Write-Host "A record for $HostAName.$ZoneName with IP $HostAIP created."

# 9) Add a PTR record that maps the IP back to the hostname
$LastOctet = ($HostAIP -split '\.')[3]
Add-DnsServerResourceRecordPtr -Name $LastOctet -ZoneName $ReverseZone -PtrDomainName "$HostAName.$ZoneName"

# 10) Open DNS port in Windows Firewall
Enable-NetFirewallRule -DisplayGroup "DNS Server"

# =========================
# VERIFICATION / TESTS
# =========================

# List zones to verify creation 
Get-DnsServerZone | Select-Object ZoneName, ZoneType, IsAutoCreated, IsReverseLookupZone

# Verify the A record
Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $HostAName

# Test forward lookup
Resolve-DnsName -Name "$HostAName.$ZoneName" -Server $DnsServerIP

# Test reverse lookup
Resolve-DnsName -Name $HostAIP -Server $DnsServerIP

# Confirm recursive resolution via forwarders
Resolve-DnsName -Name "www.microsoft.com" -Server $DnsServerIP
# =========================

# To deploy this script:
# 1) Save it as DNS-Config.ps1
# 2) Run PowerShell as Administrator
# 3) Execute the script: .\DNS-Config.ps1