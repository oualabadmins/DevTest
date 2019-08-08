<## AddUsers.ps1
## Adds user to a domain
## 1/31/2017 - Updated Restart ADWS to be more robust and to start dependencies
##>

<# Restart ADWS to ensure script commands will work
$svc = Get-Service ADWS
if ($svc.Status -ne "Running") {
$netlogon = Get-Service netlogon
	if ($netlogon.Status -ne "Running") {
		$netlogon | Start-Service | Out-Null
		$netlogon.WaitForStatus('Running')
		}
$svc | Start-Service | Out-Null
$svc = Get-Service ADWS
$svc.WaitForStatus('Running')
}
#>

# TEST sleep 60, restart ADWS, sleep 60
sleep 300
#$svc = Get-Service ADWS
#$svc | Restart-Service
#$svc.WaitForStatus('Running')
#sleep 60

Import-Module ActiveDirectory

# TEST confirm AD connection
pushd
Set-Location AD: -Verbose
popd

# Get ADSI for AD objects
$Root = [ADSI]"LDAP://RootDSE"
$DN = $Root.Get("rootDomainNamingContext")
$UDN = "CN=Users," + $DN

## Create SP/O365 groups

# Create O365 Users group
#$O365Group = Get-ADGroup O365Users -ErrorAction SilentlyContinue
if ($O365Group -eq $null){
	New-ADGroup -Name "O365 Users" -SamAccountName O365Users -GroupCategory Security -GroupScope Global `
	-DisplayName "O365 Users" -Path "$UDN" -Description "Members of this group have the UPN <user>@$UPN"
	}

# Create Farm Admins group
#$FarmAdminsGroup = Get-ADGroup SPFarmAdmins -ErrorAction SilentlyContinue
if ($FarmAdminsGroup -eq $null){
	New-ADGroup -Name "SharePoint Farm Admins" -SamAccountName SPFarmAdmins -GroupCategory Security -GroupScope Global `
	-DisplayName "SharePoint Farm Admins" -Path "$UDN"
	}

# Create Site Collection Admins group
#$SCAdminsGroup = Get-ADGroup SPSiteCollectionAdmins -ErrorAction SilentlyContinue
if ($SCAdminsGroup -eq $null){
	New-ADGroup -Name "SharePoint Site Collection Admins" -SamAccountName SPSiteCollectionAdmins -GroupCategory Security `
	-GroupScope Global -DisplayName "SharePoint Site Collection Admins" -Path "$UDN"
	}

# Create Site Collection Members group
#$membersGroup = Get-ADGroup SPSiteCollectionMembers -ErrorAction SilentlyContinue
if ($membersGroup -eq $null){
	New-ADGroup -Name "SharePoint Site Collection Members" -SamAccountName SPSiteCollectionMembers -GroupCategory Security `
	-GroupScope Global -DisplayName "SharePoint Site Collection Members" -Path "$UDN"
	}

## Import accounts from userlist.json to AD, and add to groups

$DomainAdmins = Get-ADGroup -Filter {name -eq "Domain Admins"}
$userlist = (Get-Content .\userlist.json) -Join "`n" | ConvertFrom-Json

$userlist | ForEach-Object {
# Ignore account if it already exists in AD
$checkuser = Get-ADUser $_."samAccountName" -ErrorAction SilentlyContinue

if ($checkuser -eq $null){
    $userPrincipal = $_."samAccountName" + "@" + $UPN

    # Create account
    New-ADUser -Name $_.Name `
    -Path $UDN `
    -SamAccountName  $_."samAccountName" `
    -Description $_."Password"  `
    -EmailAddress $userPrincipal `
    -UserPrincipalName  $userPrincipal `
    -AccountPassword (ConvertTo-SecureString $_."Password" -AsPlainText -Force) `
    -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
    -Enabled $true

    # Add account to relevant groups by accountType
    if ($_.accountType -ne "service"){
        Add-ADGroupMember O365Users $_."samAccountName";
        }

    if ($_.accountType -eq "domainadmin"){
        Add-ADGroupMember $DomainAdmins $_."samAccountName";
        Add-ADGroupMember SPFarmAdmins $_."samAccountName";
        }

    if ($_.accountType -eq "siteadmin"){
        Add-ADGroupMember SPSiteCollectionAdmins $_."samAccountName";
        }

    if ($_.accountType -eq "user"){
        Add-ADGroupMember SPSiteCollectionMembers $_."samAccountName";
        }
    }
}
