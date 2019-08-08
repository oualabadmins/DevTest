# Skunkworks Lab - DevTest Lab Formulas v1.0

**Time to deploy**: 2 minutes

The **DevTest Lab Formulas** template provisions standard formulas to an existing DevTest Lab.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Foualabadmins%2Fdevtest%2Fmaster%2Fformulas%2Fazuredeploy.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Usage

This template is intended for deployment in a **corpnet** Azure subscription.

Click the **Deploy to Azure** button and complete the deployment form. Select a corpnet subscription such as:

+ MAXLAB R&D Self Service
+ MAXLAB R&D INT 1
+ MAXLAB R&D INT 2

Enter values for the parameters:

+ **Lab Name**: The name of the DevTest Lab.
+ **Vnet Name**: The name of the virtual network used by the DevTest lab, i.e. _maxlab-corp-scus-vnet-1_.
+ **Repo Name**: The name of the repository object where artifacts are stored. You can find this name by navigating to the DevTest lab in the Azure portal, then click **Configuration and Policies** | **Repositories** | **_\<artifact repository\>_**. The name will appear at the top of the blade, i.e. _privaterepo_289_. This value is **NOT** the actual name of the repository itself, or the friendly name you gave the repository when you added it to the DevTest lab.
+ **Local Admin User Name**: Use our standard lab local admin username.
+ **Local Admin Password**: Use our standard lab local admin user password in the main key vault.
+ **Domain Name**: FQDN of the corpnet domain to join.
+ **Domain OU**: You can find this value in the main key vault under **Corpnet_Lab_OU**.
+ **Domain User Name**: Use the standard lab service account.
+ **Domain Password**: Use the standard lab service account password in the main key vault.

## Solution notes

These formulas depend on the artifacts:

+ AD
+ OfficeClient

## Known issues

___
Developed by the **MARVEL Skunkworks Lab**

![alt text](images/maxskunkworkslogo-small.jpg "MAX Skunkworks")

Author: Kelley Vice (kvice@microsoft.com)  
https://github.com/maxskunkworks

Last update: _8/8/2019_

## Changelog

+ **8/8/2019**: Original commit.
