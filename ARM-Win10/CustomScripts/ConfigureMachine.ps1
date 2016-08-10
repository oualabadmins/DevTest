## ConfigureMachine extension
## kelley 8/9/2016

# Launch elevated prompt - all subsequent code will run in a new elevated prompt
##### ELEVATE IN x64 #####
## 5/17/2016 ##

$WID=[System.Security.Principal.WindowsIdentity]::GetCurrent();
$WIP=new-object System.Security.Principal.WindowsPrincipal($WID);
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator;
If ($WIP.IsInRole($adminRole)){
}
else {
    $newProcess = new-object System.Diagnostics.ProcessStartInfo 'PowerShell';
    $newProcess.Arguments = $myInvocation.MyCommand.Definition
    $newProcess.Verb = 'runas'
    [System.Diagnostics.Process]::Start($newProcess)
    exit
    }

# Confirm elevation, x64
If ($WIP.IsInRole($adminRole)){
  Write-Host "Elevated: True" -f Green}
$x64 = [Environment]::Is64BitProcess
Write-Host "64-bit:    " $x64 -f Green

##### END ELEVATION CODE #####

    # Disable UserAccessControl
    Write-Host
    Write-Host "Configuring " -NoNewline; Write-Host "UAC" -f Cyan -NoNewline; Write-Host "..."
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
    Write-Host "Done." -f Green

    # Add OSS UA Lab Users and Redmond Domain Users groups to local admins
    Write-Host
    Write-Host "Configuring " -NoNewline; Write-Host "access for Lab Users and Domain Users groups" -f Cyan -NoNewline; Write-Host "..."
    $computer = $env:computername
    $group = [ADSI]"WinNT://./Administrators,group" 
    $domain = "REDMOND"
    $group1 = "OSS UA Lab Users"
    $group2 = "oualabadmins"
    $group.add("WinNT://$domain/$group1,Group")
    $group.add("WinNT://$domain/$group2,Group")
    Write-Host "Done." -f Green

# Run BBApps script

# Create C:\Scripts
    $FolderPath = New-Item -Path C:\Scripts -ItemType Directory -ErrorAction SilentlyContinue

# Copy files to remote client
    Write-Host
    Write-Host "Copying files..." -NoNewline; Write-Host "..."  
    Copy-Item -Path "\\osscpublibsrv3.osscpub.selfhost.corp.microsoft.com\Library\Install\Charles\Configure Charles.lnk" "C:\Scripts"
	Copy-Item -Path "\\osscpublibsrv3.osscpub.selfhost.corp.microsoft.com\Library\Scripts\RDS\Office\Install Office Clients.lnk" "C:\Scripts"
    Copy-Item -Path "\\osscpublibsrv3.osscpub.selfhost.corp.microsoft.com\Library\Scripts\RDS\Charles\InstallCharlesLocal.ps1" "C:\Scripts"
    Copy-Item -Path "\\osscpublibsrv3.osscpub.selfhost.corp.microsoft.com\Library\Install\Charles\charles-proxy*.msi" "C:\Scripts"
    Copy-Item -Path "\\osscpublibsrv3.osscpub.selfhost.corp.microsoft.com\Library\Install\Charles\charles.config" "C:\Scripts"
    Copy-Item -Path "\\osscpublibsrv3.osscpub.selfhost.corp.microsoft.com\Library\Install\Charles\Charles.ini" "C:\Scripts"
    Copy-Item -Path "\\osscpublibsrv3.osscpub.selfhost.corp.microsoft.com\Library\Scripts\RDS\Charles\ConfigureCharlesUser.ps1" "C:\Scripts"
    Copy-Item -Path "\\osscpublibsrv3.osscpub.selfhost.corp.microsoft.com\Library\Scripts\RDS\Office\InstallOfficeClients.ps1" "C:\Scripts"
    Write-Host "Done." -f Green
   

Write-Host "Installing MAX Bug Bash software on client computer " -NoNewline; Write-Host "$ENV:COMPUTERNAME" -f Cyan -NoNewline; Write-Host "...
"
Write-Host "Installing Charles...
"
& C:\Scripts\InstallCharlesLocal.ps1 | Out-Null

Write-Host "Creating script shortcuts...
"
Copy-Item "C:\Scripts\Install Office Clients.lnk" "C:\Users\Public\Desktop"
Copy-Item "C:\Scripts\Configure Charles.lnk" "C:\Users\Public\Desktop"

Write-Host "Done." -f Green
exit