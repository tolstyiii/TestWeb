Remove-AzureRmResourceGroup -Name TestWeb

New-AzureRmResourceGroup -name testweb -Location 'North Europe'
Get-AzureRmVMSize -location 'North Europe' | where {(($_.NumberOfCores -eq "1") -or ($_.NumberOfCores -eq 2)) -and `
    ($_.MemoryInMB -le 4096) -and ($_.MemoryInMB -ge 1792)} | sort MemoryInMB | select Name

New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -Verbose -TemplateFile "D:\Git\TemplatesARM\StorageAcc\StorageAcc.json" -TemplateParameterFile "D:\Git\TemplatesARM\StorageAcc\StorageAcc.Parameters.json"
New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -Verbose -TemplateFile "D:\Git\TemplatesARM\Networks\network.json" -TemplateParameterFile "D:\Git\TemplatesARM\Networks\Network.Parameters.json"

$Lb = Get-AzureRmLoadBalancer
Get-AzureRmLoadBalancer | fl *
Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $LB
$lb.InboundNatRules

New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\Networks\Network.json" -TemplateParameterFile "D:\Git\TemplatesARM\Networks\Network.Parameters.json" -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\LoadBalancer\LB.json" -TemplateParameterFile "D:\Git\TemplatesARM\LoadBalancer\LB.Parameters.json" -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\VM\VM.json" -TemplateParameterFile "D:\Git\TemplatesARM\VM\VM.Parameters.json" -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\resources\Test2VMsAndLB.json" -Verbose

Get-AzureRmPublicIPAddress -ResourceGroupName "testweb" -Name "testweb-publicIPAddressName" | select IpAddress

New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\Main.json" -TemplateParameterFile "D:\Git\TemplatesARM\Main.Parameters.json" -Verbose
Test-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\VM\1VMFull.json" -TemplateParameterFile "D:\Git\TemplatesARM\VM\1VMFull.Parameters.json" -Debug
