# The NICs facing the customer network
$prodNicName1 = "Prod1"
$prodNicName2 = "Prod2"
# The NICs used for the iSCSI traffic
$iSCSINicName1 = "iSCSI1"
$iSCSINicName2 = "iSCSI2"

## No need to change these variables
$productionTeamName = "Production"
$productionvSwitchName = "Production_vSwitch"
$liveMigrationVlan=200
$csvVlan=300
$heartbeatVlan=400
$iSCSI01vSwitchName = "iSCSI-01_vSwitch"
$iSCSI02vSwitchName = "iSCSI-02_vSwitch"



### Create the necessary teams
## The Production Team (Active / Active, but switch independent)
New-NetLbfoTeam -Name "$productionTeamName" -TeamMembers "$prodNicName1","$prodNicName2" -TeamingMode SwitchIndependent -LoadBalancingAlgorithm HyperVPort -confirm:$false


### Create the vSwitches. It is important to NOT use "allowmanagementos" here. Also this is where you need to set the bandwidthmode. If not done, this can´t be changed later!


## Production vSwitch
New-VMSwitch -Name "$productionvSwitchName" -NetAdapterName "$productionTeamName" -AllowManagementOS $false -MinimumBandwidthMode weight -notes "via Ethernet Adapter '$productionTeamName' (netlbfo team)"

## iSCSI vSwitch 1
New-VMSwitch -Name "$iSCSI01vSwitchName" -NetAdapterName "$iSCSINicName1" -AllowManagementOS $false -MinimumBandwidthMode weight -notes "via Ethernet Adapter '$iSCSINicName1'"
## iSCSI vSwitch 2
New-VMSwitch -Name "$iSCSI02vSwitchName" -NetAdapterName "$iSCSINicName2" -AllowManagementOS $false -MinimumBandwidthMode weight -notes "via Ethernet Adapter '$iSCSINicName2'"


### Create virtual NICs
## on the production vSwitch
Add-VMNetworkAdapter -Name "CSV" -ManagementOS -SwitchName "$productionvSwitchName"
Add-VMNetworkAdapter -Name "Heartbeat" -ManagementOS -SwitchName "$productionvSwitchName"
Add-VMNetworkAdapter -Name "LiveMigration" -ManagementOS -SwitchName "$productionvSwitchName"
## on iSCSI vSwitch 01
Add-VMNetworkAdapter -Name "iSCSI-FE-01" -ManagementOS -SwitchName "$iSCSI01vSwitchName"
Add-VMNetworkAdapter -Name "iSCSI-MR-01" -ManagementOS -SwitchName "$iSCSI01vSwitchName"
## on iSCSI vSwitch 02
Add-VMNetworkAdapter -Name "iSCSI-FE-02" -ManagementOS -SwitchName "$iSCSI02vSwitchName"
Add-VMNetworkAdapter -Name "iSCSI-MR-02" -ManagementOS -SwitchName "$iSCSI02vSwitchName"


### Assign VLANs to the cross connected port, to segregate networks (VLANs are chosen "at will")
## Networks on Cluster Switch
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "Heartbeat" -vlanid $heartbeatVlan -access
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "CSV" -vlanid $csvVlan -access
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "LiveMigration" -vlanid $liveMigrationVlan -access
## Networks on iSCSI 01 - direct connected - VLAN IDs chosen randomly
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "iSCSI-FE-01" -vlanid 201 -access
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "iSCSI-MR-01" -vlanid 101 –access

## Networks on iSCSI 02 - direct connected - VLAN IDs chosen randomly
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "iSCSI-FE-02" -vlanid 202 -access
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "iSCSI-MR-02" -vlanid 102 -access


### Assign the bandwidth settings
## Ensure that the Management Network has always priority to keep control over the cluster
Set-VMNetworkAdapter -ManagementOS -Name "Heartbeat" -MinimumBandwidthWeight 100
Set-VMNetworkAdapter -ManagementOS -Name "CSV" -MinimumBandwidthWeight 90
Set-VMNetworkAdapter -ManagementOS -Name "LiveMigration" -MinimumBandwidthWeight 20
## iSCSI vSwitch 1
Set-VMNetworkAdapter -ManagementOS -Name "iSCSI-MR-01" -MinimumBandwidthWeight 100
Set-VMNetworkAdapter -ManagementOS -Name "iSCSI-FE-01" -MinimumBandwidthWeight 80
## iSCSI vSwitch 2
Set-VMNetworkAdapter -ManagementOS -Name "iSCSI-MR-02" -MinimumBandwidthWeight 100
Set-VMNetworkAdapter -ManagementOS -Name "iSCSI-FE-02" -MinimumBandwidthWeight 80

