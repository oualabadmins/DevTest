<## Install BB Apps
	kvice 6/28/2016

	7/28/2016 - Updated shortcut creation filenames
	8/2/2016 - Added elevation code, added OUALAB Admins to local admins group
	8/17/2016 - Moved common non-BB tasks to default_settings.ps1 in Common artifact, updated to simplify tasks
	1/31/2017 - Updated to copy files from \\max-share.osscpub.selfhost.corp.microsoft.com\Library\Scripts\RDS
	3/14/2017 - Revised to copy .zip file from blob storage instead of max-share, and unzip on target computer
	4/20/2017 - Added script to force BB VMs to go through PROXIMAX-1 for support.officeppe.com
	8/7/2019  - Removed PROXIMAX code, added Office version param
##>

param([string]$global:version)

##### ELEVATE IN x64 #####
## 5/17/2016 ##

$WID=[System.Security.Principal.WindowsIdentity]::GetCurrent();
$WIP=new-object System.Security.Principal.WindowsPrincipal($WID);
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator;
If ($WIP.IsInRole($adminRole)){}
else {
    $newProcess = new-object System.Diagnostics.ProcessStartInfo 'PowerShell';
    $newProcess.Arguments = $myInvocation.MyCommand.Definition
    $newProcess.Verb = 'runas'
    [System.Diagnostics.Process]::Start($newProcess)
    exit
    }

##### END ELEVATION CODE #####

# Base config settings

	# Add OSS UA Lab Users and oualabadmins groups to local admins
	$group = [ADSI]"WinNT://./Administrators,group" 
    $domain = "redmond"
    $group1 = "OSS UA Lab Users"
    $group2 = "oualabadmins"
    $group.add("WinNT://$domain/$group1,Group")
    $group.add("WinNT://$domain/$group2,Group")

	# Disable UserAccessControl
	Write-Host
	Write-Host "Configuring " -NoNewline; Write-Host "UAC" -f Cyan -NoNewline; Write-Host "..."
	Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
	Write-Host "Done." -f Green

	# Install .NET 3.5
	Add-WindowsFeature NET-Framework-Core

	# Disable IE ESC
	$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
	$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
	Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
	Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

	# Disable Server Manager at startup
	Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Server Manager\" -TaskName "ServerManager"
	
	# Set power management plan to High Performance
	Start-Process -FilePath "$env:SystemRoot\system32\powercfg.exe" -ArgumentList "/s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -NoNewWindow
	
	# Disable warning on file open
	Push-Location
	Set-Location HKCU:
	Test-Path .\Software\Microsoft\Windows\CurrentVersion\Policies\Associations
	New-Item -Path .\Software\Microsoft\Windows\CurrentVersion\Policies -Name Associations
	Pop-Location
	New-ItemProperty -name LowRiskFileTypes -propertyType string HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations -value ".exe;.bat;.msi;.reg;.ps1;.vbs"

	# Configure Explorer (show file extensions, hidden items, replace cmd with PS in Start)
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

# Install Office and Charles

	$version = $global:version
	$share = "https://devteststaging01.blob.core.windows.net/dtl-resources/RDS/"
	$SASkey = "?sv=2018-03-28&ss=b&srt=sco&sp=rl&se=2021-08-08T04:06:58Z&st=2019-08-07T20:06:58Z&spr=https&sig=A0%2FaYC3dK5xhh1V702E%2BSXm5JuGgKFp2Xx%2F935glE7U%3D"
	$MSPPath = ($share + "Office/OfficeMSPs")

    # Create C:\Scripts folders
    $FolderPath = New-Item -Path C:\Scripts -ItemType Directory -ErrorAction SilentlyContinue

    # Copy files to remote client
	
	Invoke-WebRequest ($share + "RDS-BugBash.zip" + $SASkey) -outfile "C:\Scripts\RDS-BugBash.zip"

	# Unzip
	$shell = new-object -com shell.application
	$zip = $shell.NameSpace("C:\Scripts\RDS-BugBash.zip")
	foreach($item in $zip.items())
 		{
 		$shell.Namespace("C:\Scripts").copyhere($item)
		 }
	
	# Install Charles
	& C:\Scripts\InstallCharlesLocal.ps1 | Out-Null
	Copy-Item "C:\Scripts\Install Office Clients.lnk" "C:\Users\Public\Desktop"
	Copy-Item "C:\Scripts\Configure Charles.lnk" "C:\Users\Public\Desktop"

	# Install Office

	# Exit if existing client
	$installed = Get-WmiObject -class Win32_product | where {$_.Description -like 'Microsoft Office*' }
	if ($installed) {exit}

	# Install Office 2007 ENT
	if ($version -eq "2007")
	{
	\\products\PUBLIC\Archives\USEnglish\Applications\Office_2007\OfficeEnterprise_2007\setup.exe /adminfile ($MSPPath + "/Office2007Ent.MSP" + $SASkey) | Out-Null
	\\products\PUBLIC\Archives\USEnglish\Applications\Office_2007\Project_Professional_2007\setup.exe /adminfile ($MSPPath + "/Office2007ProjectPro.MSP" + $SASkey) | Out-Null
	\\products\PUBLIC\Archives\USEnglish\Applications\Office_2007\SharePoint_Designer_2007\setup.exe /adminfile ($MSPPath + "/Office2007SPD.MSP" + $SASkey) | Out-Null
	\\products\PUBLIC\Archives\USEnglish\Applications\Office_2007\Visio_Professional_2007\setup.exe /adminfile ($MSPPath + "/Office2007VisioPro.MSP" + $SASkey) | Out-Null
	}

	# Install Office 2010 ENT
	if ($version -eq "2010")
	{
	\\products\PUBLIC\Archives\USEnglish\Applications\Office_2010_SP1\32-bit\Office_ProfessionalPlus_2010_SP1\setup.exe /adminfile ($MSPPath + "/Office2010Pro.MSP" + $SASkey) | Out-Null
	\\products\PUBLIC\Archives\USEnglish\Applications\Office_2010_SP1\32-bit\Project_Professional_2010_SP1\setup.exe /adminfile ($MSPPath + "/Office2010ProjectPro.MSP" + $SASkey) | Out-Null
	\\products\PUBLIC\Archives\USEnglish\Applications\Office_2010_SP1\32-bit\SharePoint_Designer_2010_SP1\setup.exe /adminfile ($MSPPath + "/Office2010SPD.MSP" + $SASkey) | Out-Null
	\\products\PUBLIC\Archives\USEnglish\Applications\Office_2010_SP1\32-bit\Visio_Premium_2010_SP1\setup.exe /adminfile ($MSPPath + "/Office2010VisioPro.MSP" + $SASkey) | Out-Null
	}

	# Install Office 2013 ENT
	if ($version -eq "2013")
	{
	\\products\public\Archives\USEnglish\Applications\Office_2013\English\MSI\32-Bit\Office_Professional_2013\setup.exe /adminfile ($MSPPath + "/Office2013Pro.MSP" + $SASkey) | Out-Null
	\\products\public\Archives\USEnglish\Applications\Office_2013\English\MSI\32-Bit\Project_Professional_2013\setup.exe /adminfile ($MSPPath + "/Office2013ProjectPro.MSP" + $SASkey) | Out-Null
	\\products\public\Archives\USEnglish\Applications\Office_2013\English\MSI\32-Bit\SharePoint_Designer_2013\setup.exe /adminfile ($MSPPath + "/Office2013SPD.MSP" + $SASkey) | Out-Null
	\\products\public\Archives\USEnglish\Applications\Office_2013\English\MSI\32-Bit\Visio_Professional_2013\setup.exe /adminfile ($MSPPath + "/Office2013VisioPro.MSP" + $SASkey) | Out-Null
	}

	# Update KMS VL server and activate Office licenses
	. ($share + "Office/OfficeKMSActivation.ps1")

exit
