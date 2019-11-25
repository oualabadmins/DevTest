<############################################
 Basic Settings Automation for VMs
 OSS UA Test Lab
 kvice
 
 Rev 5 - 9/10/13 - kvice
 Rev 6 - 10/10/14 - v-hughta
 6/22/2016 - added sections: reset proxy, disable srvr mgr at startup, set pwr mgmt to high perf, disable warning on file open
 8/17/2016 - Added code to add oualabadmins and OSS UA Lab Users to local admins
 8/18/2016 - Added explorer config
 10/27/2016 - Added set time zone to PST, WUSA to autoinstall updates
 
############################################>

##### ELEVATE IN x64 #####
## 5/17/2016 ##

$WID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$WIP = new-object System.Security.Principal.WindowsPrincipal($WID);
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;
If ($WIP.IsInRole($adminRole)) {
}
else {
	$newProcess = new-object System.Diagnostics.ProcessStartInfo 'PowerShell';
	$newProcess.Arguments = $myInvocation.MyCommand.Definition
	$newProcess.Verb = 'runas'
	[System.Diagnostics.Process]::Start($newProcess)
	exit
}

# Confirm elevation, x64
If ($WIP.IsInRole($adminRole)) {
	Write-Host "Elevated: True" -f Green
}
$x64 = [Environment]::Is64BitProcess
Write-Host "64-bit:    " $x64 -f Green

##### END ELEVATION CODE #####

# Set execution policy
Set-Executionpolicy `
	-ExecutionPolicy Unrestricted  `
	-Scope Process `
	-Force

# Start WinRM
if (-not (Get-service winrm)) {
	net start Winrm
}
Enable-PSRemoting `
	-SkipNetworkProfileCheck `
	-Force 
Winrm quickconfig

# Enable Remote Desktop
(Get-WmiObject Win32_TerminalServiceSetting -Namespace root\cimv2\TerminalServices).SetAllowTsConnections(1, 1) | Out-Null
(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\TerminalServices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0) | Out-Null

# Disable IE ESC
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty `
	-Path $AdminKey `
	-Name "IsInstalled" `
	-Value 0
Set-ItemProperty `
	-Path $UserKey `
	-Name "IsInstalled" `
	-Value 0

# Disable UserAccessControl
Write-Host
Write-Host "Configuring " -NoNewline; 
Write-Host "UAC" -f Cyan -NoNewline; 
Write-Host "..."
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
Write-Host "Done." -f Green

# Reset machine proxy
netsh winhttp reset proxy

# Disable Server Manager at startup
Disable-ScheduledTask `
	-TaskPath "\Microsoft\Windows\Server Manager\" `
	-TaskName "ServerManager"

# Set power management plan to High Performance
Start-Process `
	-FilePath "$env:SystemRoot\system32\powercfg.exe" `
	-ArgumentList "/s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" `
	-NoNewWindow

# Disable warning on file open
Push-Location
Set-Location -Path "HKCU:"
Test-Path ".\Software\Microsoft\Windows\CurrentVersion\Policies\Associations"
New-Item `
	-Path ".\Software\Microsoft\Windows\CurrentVersion\Policies" `
	-Name Associations
Pop-Location
New-ItemProperty `
	-name LowRiskFileTypes `
	-propertyType string "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" `
	-value ".exe;.bat;.msi;.reg;.ps1;.vbs"

# Create new local admin account -- commenting as this may need run post install via another script
$Computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"
$LocalAdmin = $Computer.Create("User", "oualabadmin")
$LocalAdmin.SetPassword("Oss#2010")
$LocalAdmin.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
$LocalAdmin.SetInfo()
Net localgroup administrators /add $LocalAdmin.Name.ToString()

# Add OSS UA Lab Users and Redmond Domain Users groups to local admins
Write-Host
Write-Host "Configuring " -NoNewline; 
Write-Host "access for Lab Users and Domain Users groups" -f Cyan -NoNewline; 
Write-Host "..."
$computer = $env:computername
$group = [ADSI]"WinNT://./Administrators,group" 
$domain = "REDMOND"
$group1 = "OSS UA Lab Users"
$group2 = "oualabadmins"
$group.add("WinNT://$domain/$group1,Group")
$group.add("WinNT://$domain/$group2,Group")
Write-Host "Done." -f Green

# Configure Explorer (show file extensions, hidden items, replace cmd with PS in Start)
# This isn't working, key doesn't exist at deploy time
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $key Hidden 1
Set-ItemProperty $key HideFileExt 0
Set-ItemProperty $key ShowSuperHidden 1
Set-ItemProperty $key DontUserPowerShellOnWinx 0
Stop-Process -processname explorer

# Set WUSA to auto-install updates
$wusa = (New-Object -ComObject "Microsoft.Update.AutoUpdate").Settings
$wusa.NotificationLevel = 4
$wusa.ScheduledInstallationDay = 0
$wusa.IncludeRecommendedUpdates = $true
$wusa.NonAdministratorsElevated = $true
$wusa.FeaturedUpdatesEnabled = $true
$wusa.save()

# Set time zone to PST
tzutil /s "Pacific Standard Time"