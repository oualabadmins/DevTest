# Skunkworks Lab - AD Base Configuration v1.0

**Time to deploy**: 25-40 minutes

The **AD Base Configuration** template provisions a DevTest Lab test environment on an existing corpnet-connected ER circuit consisting of:

+ Windows Server 2012 R2 or 2016 Active Directory domain controller for a custom AD domain
+ Optional SQL Server
+ Application servers with IIS
+ SharePoint Servers
+ Windows 10 clients

All server VMs can be deployed with Windows Server 2012 R2, 2016 or 2019, and all VMs are automatically joined to the custom AD domain.

## Usage

This template is intended for deployment in a **corpnet-connected DevTest lab**.

Deploy from a DevTest Lab connected to this repo by selecting the base **AD Base Configuration**:

![ScreenShot](images/ad-base-config-base.png)

### Example deployment configuration:

![ScreenShot](images/ad-base-config-example.png)

### Example deployment resources:

![ScreenShot](images/ad-base-config-resources.png)

## Solution overview and deployed resources

The following resources are deployed as part of the solution:

+ **AD DC VM**: Windows Server VM configured as a domain controller and DNS.
+ **App Server VM(s)**: 0-_X_ Windows Server VM(s). IIS is installed, and C:\Files containing example.txt is shared as "Files".
+ **SQL Server**: 0-1 Windows Server VM(s) with SQL Server **2014 SP3**, **2016 SP2** or **2017**
+ **SharePoint Server**: 0-_X_ Windows Server VM(s) with SharePoint Server **2013**, **2016** or **2019**
+ **Client VM(s)**: 0-_X_ Windows 10 client(s)
+ **Storage account**: Diagnostics storage account, and client VM storage account if indicated. VMs in the deployment use managed disks, so no storage accounts are created for VHDs.
+ **Network interfaces**: 1 NIC per VM with dynamic private IP address.
+ **JoinDomain**: Each member VM uses the **JsonADDomainExtension** extension to join the domain.
+ **BGInfo**: The **BGInfo** extension is applied to all VMs.
+ **Antimalware**: The **iaaSAntimalware** extension is applied to all VMs with basic scheduled scan and exclusion settings.

## Solution notes

+ Machine tier deployment notes:
  + SQL Server: SQL is configured with the default instance name _MSSQLSERVER_ with TCP enabled on port **1433**. The user account you specified in the deployment belongs to the sysadmin role. You must log into the SQL VM with this local account to access the SQL server using the SQL Management Studio.
  + SharePoint Server: SharePoint is installed, but not configured. To provision SharePoint, either run the Configuration Wizard or use [AutoSPInstaller](https://autospinstaller.com).
+ The domain user *User1* is created in the domain and added to the Domain Admins group. User1's password is the one you provide in the *adminPassword* parameter.
+ The other machine tier's VM resources depend on the **ADDC** resource deployment to ensure that the AD domain exists prior to execution of the JoinDomain extensions. The asymmetric VM deployment adds a few minutes to the overall deployment time.
+ Remember, when you RDP to your VM, you will use **domain\adminusername** for the custom domain of your environment, _not_ your corpnet credentials.

## Known issues

+ The client VM deployment may take longer than expected, and then appear to fail. The client VMs and extensions may or may not deploy successfully. This is due to an ongoing Azure client deployment bug, and only happens when the client VM size is smaller than DS3_v2.

`Tags: TLG, Test Lab Guide, Base Configuration`
___
Developed by the **MAX Skunkworks Lab**  
Author: Kelley Vice (kvice@microsoft.com)  
https://github.com/maxskunkworks

Last update: _5/8/2019_

## Changelog

+ **8/8/2018**: Original commit, derived from https://github.com/oualabadmins/lab_deploy/tree/master/max-base-config_x-vm.
+ **8/9/2018**: Updates to output from nic.json to return DC IP value back to the main template for passing to linked app and client templates. This enables adding the DC IP to DNS settings on member VMs. Removed NSG to avoid inadvertently applying security rules to existing common virtual networks.
+ **1/16/2019**: Updated Win10 SKU to rs3-pro-test to match availability.
+ **1/23/2019**: Updated Win10 SKU to RS3-Pro - the other sku doesn't exist.
+ **5/7/2019**: Reconfigured for use in corpnet DevTest labs.
+ **5/8/2019**: Reconfigured DSC resources, added OU creation. Set member tiers to join to the custom OU to prevent joinDomain extension failures.
+ **5/14/2019**: Removed SP DSC until I can complete troubleshooting.
