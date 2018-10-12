Remove-AzureRmResourceGroup -Name testweb

New-AzureRmResourceGroup -name testweb -Location 'North Europe'
Get-AzureRmVMSize -location 'North Europe' | where {(($_.NumberOfCores -eq "1") -or ($_.NumberOfCores -eq 2)) -and `
    ($_.MemoryInMB -le 4096) -and ($_.MemoryInMB -ge 1792)} | sort MemoryInMB | select Name

$Lb = Get-AzureRmLoadBalancer
Get-AzureRmLoadBalancer | fl *
Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $LB
$lb.InboundNatRules

Get-AzureRmPublicIPAddress -ResourceGroupName "testweb" -Name "testweb-publicIPAddressName" | select IpAddress

New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\Main.json" -TemplateParameterFile "D:\Git\TemplatesARM\Main.Parameters.json" -Verbose
Test-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\Main.json" -TemplateParameterFile "D:\Git\TemplatesARM\Main.Parameters.json" -Debug
