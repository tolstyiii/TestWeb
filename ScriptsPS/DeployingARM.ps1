Get-AzureRmVirtualNetwork -Name "testweb-VNet" -ResourceGroupName testweb | fl *

New-AzureRmResourceGroupDeployment -ResourceGroupName "TestWeb" -TemplateFile "D:\Git\TemplatesARM\StorageAcc.json"
New-AzureRmResourceGroupDeployment -ResourceGroupName "testWeb" -TemplateFile "d:\Git\TemplatesARM\Networks\Network.json" -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName "testWeb" -TemplateFile "D:\Git\TemplatesARM\LoadBalancer\LB.json" -Verbose
New-AzureRmResourceGroup -Name TestWeb -Location 'North Europe'

Remove-AzureRmResourceGroup -Name TestWeb
New-AzureRmResourceGroup -name testweb -Location 'North Europe'
Get-AzureRmVMSize -location 'North Europe' | where {(($_.NumberOfCores -eq "1") -or ($_.NumberOfCores -eq 2)) -and `
    ($_.MemoryInMB -le 4096) -and ($_.MemoryInMB -ge 1792)} | sort MemoryInMB | select Name

New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\Main.json" -Verbose
