# Skunkworks Lab (DevTest) - Add client VMs to existing deployment v1.0

**Time to deploy**: ~10 minutes

The **Add client VMs to existing deployment** template provisions _x_ number of client VMs to an existing deployment and joins them to the deployment's domain. You can choose Windows 10, 8.1 or 7.

## Usage

Provide the following information:

+ Name of the configuration (the name of the top node that will appear in the DevTest lab)VNet name to which VMs will be connected
+ AD domain name
+ OU for computer accounts, with container identifier (i.e. _CN=Computers_)
+ AD username and password
+ AD DC IP address (you can get this from the DC's overview page)
+ Client OS (Windows 10, 8.1 or 7)
+ Number of client VMs to add
+ Starting number for client names (if there are existing clients, use the next unused increment)
+ VM size (generally, the default size _Standard_DS2_v2_ is sufficient)

## Solution notes

+ You cannot add computer accounts to the default _CN=Computers_ OU using the ADDomainExtension. Before deployment, check **AD Users and Computers** to see if a custom OU exists for computer account objects. If not, create one in the AD domain (for example, **OU=Machines**).

## Known issues

+ The client VM deployment may take longer than expected, and then appear to fail. The client VMs and extensions may or may not deploy successfully. This is due to an ongoing Azure client deployment bug, and only happens when the client VM size is smaller than DS3_v2.

___
Developed by the **MARVEL Skunkworks Lab**

![alt text](../common/images/maxskunkworkslogo-small.jpg "MARVEL Skunkworks")

Author: Kelley Vice (kvice@microsoft.com)  
https://github.com/maxskunkworks

Last update: _8/27/2019_

## Changelog

+ **6/19/2019**: Initial commit. Derived from oualabadmins\lab_deploy\M365-base-config_DirSync. Added parameters for vnetName, OU, clientStartNumber, dcIp.
+ **8/27/2019**: Revised for use in DevTest labs.
+ **8/28/2019**: Corrected issues preventing deployment, added code to permit OS choice.
