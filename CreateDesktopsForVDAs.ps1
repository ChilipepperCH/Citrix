<#
.SYNOPSIS
Creates a Tag per VDA and Creates a dedicated desktop to launch only against that Tag. Script by Martin Zugec

.DESCRIPTION
Creates a Tag per VDA and Creates a dedicated desktop to launch only against that Tag. Script by Martin Zugec


.EXAMPLE

.NOTES
.LINK
https://www.citrix.com/blogs/2017/04/17/how-to-assign-desktops-to-specific-servers-in-xenapp-7/
#>


Param (
	[String]$DesktopGroupName = "*", 
	[Parameter(Mandatory=$True)][Array]$UserGroups
)

# Error handling
$ErrorActionPreference = "Stop"

Add-PSSnapin Citrix*

# This is the prefix that will be used before each tag used for machine assignments. 
[String]$TagPrefix = "ServerTag_"

# First, let make sure that that every single machine have a single tag assigned to it. 
Write-Host "Processing all RDS hosts" 
ForEach ($m_VDA in $(Get-BrokerMachine -SessionSupport MultiSession -DesktopGroupName $DesktopGroupName)) {
	[String]$m_SimpleMachineName = $($m_VDA.MachineName.Split('\')[1])
	[String]$m_TagName = "$($TagPrefix)$($m_SimpleMachineName)"
	Write-Host "	$($m_SimpleMachineName): " -NoNewline
	If ($m_VDA.Tags -notcontains $m_TagName) {
		Write-Host -ForegroundColor Yellow "Desktop not found, creating"
		# Create new tag first and assign it to VDA
		New-BrokerTag -Name $m_TagName -Description "Tag used to restrict resources to machine $($m_VDA.MachineName)" | Add-BrokerTag -Machine $m_VDA | Out-Null
		
		# Create new entitlement policy rule
		New-BrokerEntitlementPolicyRule $m_SimpleMachineName -DesktopGroupUid $m_VDA.DesktopGroupUid -IncludedUsers $UserGroups -PublishedName $m_SimpleMachineName -RestrictToTag $m_TagName | Out-Null
	} Else {
		Write-Host -ForegroundColor Green "Desktop already exists"
	}
}

