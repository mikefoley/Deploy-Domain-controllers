
$NetworkList = 2,3
$clustername = get-cluster Cluster
$templatename = Get-Template "Win2012 Template for DC Builder"
$vmhost = get-vmhost "w2-haas01-esx0117.eng.vmware.com"
$datastore = Get-Datastore "CPBU_PM_PMM_4"

foreach ($net in $NetworkList) {
write-host "Doing Pass number " $net

$servername = "DC Lab "+$net

write-host = "Building " $servername
write-host = "Building OS Customization Spec number " $net
$runonce = "%systemroot%\system32\WindowsPowershell\v1.0\Powershell.exe -executionpolicy bypass -file \\10.144.119.238\Powershell\DC-Builder.ps1 -NetworkNumber $net" 

Write-Host = "Delete the old customization spec and VM if they are there."
If (Get-OSCustomizationSpec -name "LabBuild $net" -ErrorAction SilentlyContinue) 
{
Remove-OSCustomizationSpec "LabBuild $net" -Confirm:$false
}  
else 
{
Write-Host "LabBuild $net spec is not there... Continuing"
}

If (Get-VM -name $servername -ErrorAction SilentlyContinue) 
{
Remove-VM $servername -DeletePermanently -Confirm:$false
}

Get-OSCustomizationSpec -Name "DC Windows 2012" | New-OSCustomizationSpec -name "LabBuild $net" 
$osCust = Get-OSCustomizationSpec -name "LabBuild $net"
Set-OSCustomizationSpec -GuiRunOnce $runonce -OSCustomizationSpec "LabBuild $net" 


write-host "Retrieving portgroup for LabNetwork$net" 
$portgroup = Get-VirtualPortGroup -VMHost $vmhost |where {$_.Name -like "LabNetwork$net"}



write-host = "Creating new Domain Controller VM $servername on Datastore $datastore with OS Customization spec $osCust"
New-VM -Name $servername -ResourcePool $clustername -Template $templatename -OSCustomizationSpec $osCust -Datastore $datastore 

Write-Host = "Setting Network Adapter on the VM to the appropriate Portgroup"
Get-NetworkAdapter -vm $servername | Set-NetworkAdapter -NetworkName $portgroup -confirm:$false



}


