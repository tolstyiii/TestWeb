Remove-AzureRmResourceGroup -Name testweb

New-AzureRmResourceGroup -name testweb -Location 'North Europe'

$Lb = Get-AzureRmLoadBalancer
Get-AzureRmLoadBalancer | fl *
Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $LB
$lb.InboundNatRules

Get-AzureRmPublicIPAddress -ResourceGroupName "testweb" -Name "testweb-publicIPAddressName" | select IpAddress

New-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\Main.json" -TemplateParameterFile "D:\Git\TemplatesARM\Main.Parameters.json" -Verbose
Test-AzureRmResourceGroupDeployment -ResourceGroupName testweb -TemplateFile "D:\Git\TemplatesARM\Main.json" -TemplateParameterFile "D:\Git\TemplatesARM\Main.Parameters.json" -Debug

$RG = Get-AzureRmResourceGroup -Name testweb
New-AzureRmKeyVault -ResourceGroupName testweb -Name testweb-KeyVault -Location $RG.Location
$Pass = ConvertTo-SecureString 'pa$$W0rD' -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName testweb-KeyVault -Name 'TestEx' -SecretValue $Pass
(Get-AzureKeyVaultSecret -VaultName testweb-KeyVault -Name 'TestEx') | fl *
Get-AzureRmKeyVault testweb-KeyVault
Set-AzureRmKeyVaultAccessPolicy -VaultName testweb-KeyVault -EnabledForTemplateDeployment
Set-AzureRmKeyVaultAccessPolicy testweb-KeyVault 
Get-AzureRmVM -ResourceGroupName testweb