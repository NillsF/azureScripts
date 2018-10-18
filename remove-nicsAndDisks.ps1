<#
    .DESCRIPTION
        An example runbook which gets all the ARM resources using the Run As Account (Service Principal)

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: Mar 14, 2016
#>

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Get all disks/nics from all resource groups
    $rgs = Get-AzureRmResourceGroup 
    foreach ($rg in $rgs){
        $disks = get-azurermdisk -ResourceGroupName $rg.ResourceGroupName 
        foreach($disk in $disks){
            if($null -eq $disk.ManagedBy){
                Remove-AzureRmDisk -ResourceGroupName $rg.ResourceGroupName -DiskName $disk.name -asjob -Force
                Start-Sleep -s 1
            }
        }
        $nics = Get-AzureRmNetworkInterface -ResourceGroupName $rg.ResourceGroupName
        foreach($nic in $nics){
            Remove-AzureRmNetworkInterface -ResourceGroupName $rg.ResourceGroupName -Name $nic.name -force -AsJob
            $nic.name
            Start-Sleep -s 1
        }
    }
