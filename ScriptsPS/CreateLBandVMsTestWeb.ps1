Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Import-Module AzureRM
Connect-AzureRmAccount

#Создаем ресурсную группу
New-AzureRmResourceGroup -ResourceGroupName "TestWeb" -Location "North Europe"

#Создаем балансер. Изначально создадим для него публичный адрес.
$publicIP = New-AzureRmPublicIpAddress -ResourceGroupName "TestWeb" -Location "North Europe" -AllocationMethod "Dynamic" -Name "TestWeb-PublicIP"
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name "TestWeb-lbFront" -PublicIpAddress $publicIP
$backendPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "TestWeb-lbBack"
$lb = New-AzureRmLoadBalancer -ResourceGroupName "TestWeb" -Name "TestWeb-lb" -Location "North Europe" -FrontendIpConfiguration $frontendIP -BackendAddressPool $backendPool

#Создаем проверку доступности нод за блансером
Add-AzureRmLoadBalancerProbeConfig -Name "TestWeb-Probe80" -LoadBalancer $lb -Protocol tcp -Port 80 -IntervalInSeconds 15 -ProbeCount 2
Set-AzureRmLoadBalancer -LoadBalancer $lb

#Создаем правило балансировки между живыми нодами
$probe = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "TestWeb-Probe80"

Add-AzureRmLoadBalancerRuleConfig -Name "TestWeb-lbRule" -LoadBalancer $lb -FrontendIpConfiguration $lb.FrontendIpConfigurations[0] -BackendAddressPool $lb.BackendAddressPools[0] `
  -Protocol Tcp -FrontendPort 80 -BackendPort 80 -Probe $probe

Set-AzureRmLoadBalancer -LoadBalancer $lb

#Создаем сети
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name "TestWeb-Subnet192" -AddressPrefix 192.168.192.0/24
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName "TestWeb" -Location "North Europe" -Name "TestWeb-Vnet" -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

#Создаем сетевые интерфейсы для машинок
for ($i=1; $i -le 2; $i++)
{
   New-AzureRmNetworkInterface -ResourceGroupName "TestWeb" -Name "Server$i" -Location "North Europe" -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0]
}

#Создаем группу доступности
$availabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName "TestWeb" -Name "TestWeb-AvailabilitySet" -Location "North Europe" -Sku aligned -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2

#Проверяем доступные сайзы ВМ в регионе
#Get-AzureRmVMSize -Location "North Europe" | where {$_.NumberOfCores -eq 1}
#Создаем ВМ и объединяем в группу доступности
$UserName = 'sa'
$Password = 'LiLPbQ58Nsus' | ConvertTo-SecureString -AsPlainText -Force
$cred = [pscredential]::new($Username,$Password)

for ($i=1; $i -le 2; $i++)
{
    New-AzureRmVm -ResourceGroupName "TestWeb" -Name "Server$i" -Location "North Europe" -VirtualNetworkName "TestWeb-Vnet" -SubnetName "TestWeb-Subnet192" `
     -SecurityGroupName "TestWeb-NetworkSecurityGroup" -OpenPorts 80,3389 -AvailabilitySetName "TestWeb-AvailabilitySet" -Credential $cred -Size "Standard_A1" -AsJob
}

#Устанавливаем роль IIS
for ($i=1; $i -le 2; $i++)
{
   Set-AzureRmVMExtension -ResourceGroupName "TestWeb" -ExtensionName "IIS" -VMName Server$i -Publisher Microsoft.Compute -ExtensionType CustomScriptExtension -TypeHandlerVersion 1.8 `
     -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
     -Location "North Europe"
}

#Создание правил NAT для RDP на машинки
for ($i=1; $i -le 2; $i++)
{
    $slb = Get-AzureRmLoadBalancer -Name "TestWeb-lb" -ResourceGroupName "TestWeb"
    $slb | Add-AzureRmLoadBalancerInboundNatRuleConfig -Name "Server$i" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort "3389$i" -BackendPort 3389
    Set-AzureRmLoadBalancer -LoadBalancer $slb
    $nic = Get-AzureRmNetworkInterface -ResourceGroupName "TestWeb" -Name "Server$i"
    $nic.IpConfigurations[0].LoadBalancerInboundNatRules.Add($slb.InboundNatRules[$i-1])
    Set-AzureRmNetworkInterface -NetworkInterface $nic
}

#Настройка доступности РДП только из копоративной сети
$nsg = Get-AzureRmNetworkSecurityGroup -Name  TestWeb-NetworkSecurityGroup -ResourceGroupName TestWeb
$nsg | Remove-AzureRmNetworkSecurityRuleConfig -Name TestWeb-NetworkSecurityGroup3389
$nsg | Add-AzureRmNetworkSecurityRuleConfig -SourceAddressPrefix "86.57.255.88/29" -Name "TestWeb-NetworkSecurityGroup3389" -Description "RDP to WebServers" -Protocol Tcp -SourcePortRange * `
    -DestinationPortRange "3389" -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Inbound 
$nsg | Set-AzureRmNetworkSecurityGroup

#Настройка бекапа

############################################################################################################################################################################

#Создаем lb2 и доп. машинку в другой географической локации
$publicIPA = New-AzureRmPublicIpAddress -ResourceGroupName "TestWeb" -Location "East Asia" -AllocationMethod "Dynamic" -Name "TestWeb-PublicIPA"
$frontendIPA = New-AzureRmLoadBalancerFrontendIpConfig -Name "TestWeb-lbFrontA" -PublicIpAddress $publicIPA
$backendPoolA = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "TestWeb-lbBackA"
$lbA = New-AzureRmLoadBalancer -ResourceGroupName "TestWeb" -Name "TestWeb-lbA" -Location "East Asia" -FrontendIpConfiguration $frontendIPA -BackendAddressPool $backendPoolA



#Создаем сети
$subnetConfigA = New-AzureRmVirtualNetworkSubnetConfig -Name "TestWeb-SubnetA92" -AddressPrefix 192.168.92.0/24
$vnetA = New-AzureRmVirtualNetwork -ResourceGroupName "TestWeb" -Location "East Asia" -Name "TestWeb-VnetA" -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfigA

#Создаем сетевые интерфейсы для машинок
New-AzureRmNetworkInterface -ResourceGroupName "TestWeb" -Name "Server3" -Location "East Asia" -Subnet $vnetA.Subnets[0] -LoadBalancerBackendAddressPool $lbA.BackendAddressPools[0]

#Создаем группу доступности
$availabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName "TestWeb" -Name "TestWeb-AvailabilitySetA" -Location "East Asia" -Sku aligned -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2

#Проверяем доступные сайзы ВМ в регионе
#Get-AzureRmVMSize -Location "North Europe" | where {$_.NumberOfCores -eq 1}
#Создаем ВМ и объединяем в группу доступности
New-AzureRmVm -ResourceGroupName "TestWeb" -Name "Server3" -Location "East Asia" -VirtualNetworkName "TestWeb-VnetA" -SubnetName "TestWeb-Subnet92" `
     -SecurityGroupName "TestWeb-NetworkSecurityGroup" -OpenPorts 80,3389 -AvailabilitySetName "TestWeb-AvailabilitySetA" -Credential $cred -Size "Standard_A1" -AsJob

#Устанавливаем роль IIS
Set-AzureRmVMExtension -ResourceGroupName "TestWeb" -ExtensionName "IIS" -VMName Server3 -Publisher Microsoft.Compute -ExtensionType CustomScriptExtension -TypeHandlerVersion 1.8 `
    -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
    -Location "East Asia"

#Создание правил NAT для RDP на машинки
$slbA = Get-AzureRmLoadBalancer -Name "TestWeb-lbA" -ResourceGroupName "TestWeb"
$slbA | Add-AzureRmLoadBalancerInboundNatRuleConfig -Name "Server3" -FrontendIpConfiguration $frontendIPA -Protocol TCP -FrontendPort "33893" -BackendPort 3389
Set-AzureRmLoadBalancer -LoadBalancer $slbA
$nicA = Get-AzureRmNetworkInterface -ResourceGroupName "TestWeb" -Name "Server3"
$nicA.IpConfigurations[0].LoadBalancerInboundNatRules.Add($slbA.InboundNatRules[0])
Set-AzureRmNetworkInterface -NetworkInterface $nicA

#Создаем проверку доступности нод за блансером
Add-AzureRmLoadBalancerProbeConfig -Name "TestWeb-ProbeA80" -LoadBalancer $lbA -Protocol tcp -Port 80 -IntervalInSeconds 15 -ProbeCount 2
Set-AzureRmLoadBalancer -LoadBalancer $lbA

#Создаем правило балансировки между живыми нодами
$probeA = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lbA -Name "TestWeb-ProbeA80"

Add-AzureRmLoadBalancerRuleConfig -Name "TestWeb-lbRuleA" -LoadBalancer $lbA -FrontendIpConfiguration $lbA.FrontendIpConfigurations[0] -BackendAddressPool $lbA.BackendAddressPools[0] `
  -Protocol Tcp -FrontendPort 80 -BackendPort 80 -Probe $probeA

Set-AzureRmLoadBalancer -LoadBalancer $lbA


########################################################################################################################################################################

#Создаем сторадж аккаунт для хранения бекапов
New-AzureRmStorageAccount -ResourceGroupName TestWeb -Name "testwebstorageacc" -SkuName Standard_LRS -Location 'North Europe' -Kind BlobStorage -AccessTier Hot

#DSC

#Создаем Automation account
New-AzureRmAutomationAccount -ResourceGroupName "TestWeb" -Name "TestWeb-AutoAcc" -Location 'North Europe'

#Импортируем подготовленный DSCConfig с локального компа в эйжур
Import-AzureRmAutomationDscConfiguration -SourcePath "d:\ScriptsPS\DSC\TestDocsAzureAutomation\TestConfig.ps1" -ResourceGroupName TestWeb -AutomationAccountName "TestWeb-AutoAcc" -Description `
     "Test config for IIS on Server3" -Published

#Копилируем файл конфигурации .MOF и загружаем его на втроенный в AzureAutomation Pull-Server
$CompilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName TestWeb -AutomationAccountName TestWeb-AutoAcc -ConfigurationName "TestConfig"
while ($CompilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null){
    $CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
    Start-Sleep -Seconds 3
}
$CompilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any

#Регистрируем ноды в Automation Account
$Nodes = "Server1,Server2,Server3"
Register-AzureRmAutomationDscNode -AzureVMName Server1 -AutomationAccountName TestWeb-AutoAcc -NodeConfigurationName "TestWeb-WebServer" -ConfigurationMode ApplyAndMonitor -ActionAfterReboot ContinueConfiguration -ResourceGroupName TestWeb

#Remove-AzureRmResourceGroup -Name "TestWeb"
#Get-AzureRmResource | where {$_.Name -like "*server3/IIs*"} | Remove-AzureRmResource -Force
#Get-AzureRmResource | ft

Get-AzureRmVM