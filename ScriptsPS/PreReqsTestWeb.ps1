#Создаем ресурсную группу automation account
$RGName = "testweb"
$AAName = $RGName+"-AutoAcc"
$userPrincipalName='tolstyiii@mail.ru'
$keyVaultName = "testweb-keyvault"
New-AzureRmResourceGroup -name testweb -Location 'North Europe'
$RG = Get-AzureRmResourceGroup $RGName
New-AzureRmAutomationAccount -ResourceGroupName $RG.ResourceGroupName -Name $AAName -Location $RG.Location

#Создаем Key Vault
New-AzureRmKeyVault `
  -VaultName $keyVaultName `
  -resourceGroupName $resourceGroupName `
  -Location $location `
  -EnabledForTemplateDeployment

#Создаем секрет для юзания в качестве пароля УЗ админа на ВМ
$PassVM = ConvertTo-SecureString -String "LiLPbQ58Nsus" -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name "testwebVM" -SecretValue $PassVM

#Передаем primary key в key vault
$Account = Get-AzureRmAutomationAccount -ResourceGroupName $RGName -Name $AAName | fl *
$RegistrationInfo = $Account | Get-AzureRmAutomationRegistrationInfo
$primaryKey = $RegistrationInfo.PrimaryKey
$AAPrKey = ConvertTo-SecureString -String $RegistrationInfo.PrimaryKey -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name "AAPrKey" -SecretValue $AAPrKey

Import-AzureRmAutomationDscNodeConfiguration -Path "d:\Git\ScriptsPS\DSC\testweb-Server1.mof" -ConfigurationName "WebServer" -ResourceGroupName "testweb" -AutomationAccountName "testweb-AutoAcc" -Force
Import-AzureRmAutomationDscNodeConfiguration -Path "d:\Git\ScriptsPS\DSC\testweb-Server2.mof" -ConfigurationName "WebServer" -ResourceGroupName "testweb" -AutomationAccountName "testweb-AutoAcc" -Force