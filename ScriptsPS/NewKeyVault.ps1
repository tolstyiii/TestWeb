$keyVaultName = "testweb-keyvault"
$resourceGroupName="testweb"
$location='northeurope'
$userPrincipalName='tolstyiii@mail.ru'

New-AzureRmKeyVault `
  -VaultName $keyVaultName `
  -resourceGroupName $resourceGroupName `
  -Location $location `
  -EnabledForTemplateDeployment

# Create a secret with the name, vmAdminPassword
Add-Type -AssemblyName System.Web
$password = [System.Web.Security.Membership]::GeneratePassword(16,3)
echo $password
$secretvalue = ConvertTo-SecureString $password -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name "vmAdminPassword" -SecretValue $secretvalue

# Add elseone secret to key vault for our testing VMs
$PassVM = ConvertTo-SecureString -String "LiLPbQ58Nsus" -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name "testwebVM" -SecretValue $PassVM