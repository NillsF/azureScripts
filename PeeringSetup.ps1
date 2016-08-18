#logging into azure
add-azurermaccount
#register the feature
Register-AzureRmProviderFeature -FeatureName AllowVnetPeering -ProviderNamespace Microsoft.Network

Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Network
#My variables, sorry for the bad naming; I did this a bit too quickly
$vnet1name = "VNETpeering-vnet"
$vnet2name = "VNETpeeringvnet949"
$rgname = "VNETpeering"

#get vnets
$vnet1 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgname -Name $vnet1name
$vnet2 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgname -Name $vnet2name

#now this is a bit tricky, a peering relationship needs to be setup twice, once 1==>2; and once 2==>1
Add-AzureRmVirtualNetworkPeering -name From1To2 -VirtualNetwork $vnet1 -RemoteVirtualNetworkId $vnet2.id 
Add-AzureRmVirtualNetworkPeering -name From2To1 -VirtualNetwork $vnet2 -RemoteVirtualNetworkId $vnet1.id 
#all setup and ready to go