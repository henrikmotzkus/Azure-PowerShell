# VM anlegen

$subnetName = $ResourceGroupName + "_subnet"
$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.1.0.0/24"
$vnetName = $ResourceGroupName + "_vnet"
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix "10.1.0.0/24" -Subnet $singleSubnet
$ipName = $ResourceGroupName + "_pubip"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $ResourceGroupName -Location $LocationName -AllocationMethod Dynamic
$nicName = $ResourceGroupName + "_nic"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
$cred = Get-Credential
$vmName = $ResourceGroupName  + "vm"
$vmSize = "Standard_F4"
$computerName = $ResourceGroupName  + "vm"
$osDiskName = "osdisk.vhd"
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccName
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Linux -ComputerName $computerName -Credential $cred
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
$osDiskUri = '{0}vhds/{1}-{2}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $urlOfUploadedImageVhd -Linux
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $vm
