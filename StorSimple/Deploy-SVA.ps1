# Deployment StorSimple Virtual Array
# Henrik Motzkus

$LocationName = "West Europe"
$RessourceGroupName = "yourrgname"
$StorageAccountName = $RessourceGroupName + "storage"
$SubscriptionId = "YOUR SUBSCRIPTION ID"


$AzureCtx = login-azurermaccount
$Subscription = Select-AzureRmSubscription -SubscriptionId $SubscriptionId
$ResourceGroup = New-AzureRmResourceGroup -Name $RessourceGroupName -Location $LocationName
$StorageAccount = New-AzureRmStorageAccount -StorageAccountName $StorageAccountName -Location $LocationName -Type Standard_LRS -ResourceGroupName $RessourceGroupName
$urlOfUploadedImageVhd = "https://" + $StorageAccountName + ".blob.core.windows.net/images/hcs.vhd"
$fd = New-Object system.windows.forms.openfiledialog
$fd.InitialDirectory = 'c:\'
$fd.MultiSelect = $true
$fd.showdialog()
Add-AzureRmVhd -ResourceGroupName $RessourceGroupName -Destination $urlOfUploadedImageVhd -LocalFilePath $fd.filenames[0].ToString()
$subnetName = $RessourceGroupName + "_subnet"
$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.1.0.0/24"
$vnetName = $RessourceGroupName + "_vnet"
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $RessourceGroupName -Location $LocationName -AddressPrefix "10.1.0.0/24" -Subnet $singleSubnet
$ipName = $RessourceGroupName + "_pubip"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $RessourceGroupName -Location $LocationName -AllocationMethod Dynamic
$nicName = $RessourceGroupName + "_svanic"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $RessourceGroupName -Location $LocationName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
$cred = Get-Credential
$vmName = $RessourceGroupName  + "vm"
$vmSize = "Standard_F4"
$computerName = $RessourceGroupName  + "vm"
$osDiskName = "hcs.vhd"
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $RessourceGroupName -AccountName $StorageAccountName
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
$osDiskUri = '{0}vhds/{1}-{2}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $urlOfUploadedImageVhd -Windows
$urlOfDataVhd = "https://" + $StorageAccountName + ".blob.core.windows.net/vhds/datadisk1.vhd"
$vm = Add-AzureRmVMDataDisk -VM $vm -Name "datadisk" -VhdUri $urlOfDataVhd -LUN 0 -Caching ReadWrite -DiskSizeinGB 500 -CreateOption Empty
New-AzureRmVM -ResourceGroupName $RessourceGroupName -Location $LocationName -VM $vm



