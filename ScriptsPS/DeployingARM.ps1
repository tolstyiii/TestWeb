Get-AzureRmResource | where {$_.Name -like "*storage*"} | Remove-AzureRmStorageAccount

New-AzureRmResourceGroupDeployment -ResourceGroupName "TestWeb" -TemplateFile "D:\TemplatesARM\StorageAcc.json"
New-AzureRmResourceGroupDeployment -ResourceGroupName "testWeb" -TemplateFile "d:\TemplatesARM\Networks\Network.json" -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName "testWeb" -TemplateFile "D:\TemplatesARM\TestWebFirstMachineAndPreReq.json" -Verbose
New-AzureRmResourceGroup -Name TestWeb -Location 'North Europe'

Remove-AzureRmResourceGroup -Name TestWeb
New-AzureRmResourceGroup -name testweb -Location 'North Europe'
Get-AzureRmVMSize -location 'North Europe' | where {(($_.NumberOfCores -eq "1") -or ($_.NumberOfCores -eq 2)) -and `
    ($_.MemoryInMB -le 4096) -and ($_.MemoryInMB -ge 1792)} | sort MemoryInMB | select Name