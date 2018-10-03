# log in to both Azure Service Management and Azure Resource Manager
Add-AzureAccount
Connect-AzureRmAccount

# fill in correct values for your VM/Automation account here
$VMName = 'Server1'
$ServiceName = 'WebServer'
$AutomationAccountName = 'TestWeb-AutoAcc'
$AutomationAccountResourceGroup = 'TestWeb'

# fill in the name of a Node Configuration in Azure Automation State Configuration, for this VM to conform to
# NOTE: DSC Node Configuration names are case sensitive in the portal.
$NodeConfigName = 'TestWeb-NorthEurope'

# get Azure Automation State Configuration registration info
$Account = Get-AzureRmAutomationAccount -ResourceGroupName $AutomationAccountResourceGroup -Name $AutomationAccountName
$RegistrationInfo = $Account | Get-AzureRmAutomationRegistrationInfo

# use the DSC extension to onboard the VM for management with Azure Automation State Configuration
$VM = Get-AzureVM -Name $VMName -ServiceName $ServiceName

$PublicConfiguration = ConvertTo-Json -Depth 8 @{
    SasToken = ''
    ModulesUrl = 'https://eus2oaasibizamarketprod1.blob.core.windows.net/automationdscpreview/RegistrationMetaConfigV2.zip'
    ConfigurationFunction = 'RegistrationMetaConfigV2.ps1\RegistrationMetaConfigV2'

# update these PowerShell DSC Local Configuration Manager defaults if they do not match your use case.
# See https://docs.microsoft.com/powershell/dsc/metaConfig for more details
    Properties = @{
        RegistrationKey = @{
            UserName = 'notused'
            Password = 'PrivateSettingsRef:RegistrationKey'
        }
        RegistrationUrl = $RegistrationInfo.Endpoint
        NodeConfigurationName = $NodeConfigName
        ConfigurationMode = 'ApplyAndMonitor'
        ConfigurationModeFrequencyMins = 15
        RefreshFrequencyMins = 30
        RebootNodeIfNeeded = $False
        ActionAfterReboot = 'ContinueConfiguration'
        AllowModuleOverwrite = $False
    }
}

$PrivateConfiguration = ConvertTo-Json -Depth 8 @{
    Items = @{
        RegistrationKey = $RegistrationInfo.PrimaryKey
    }
}

$VM = Set-AzureVMExtension `
    -VM $vm `
    -Publisher Microsoft.Powershell `
    -ExtensionName DSC `
    -Version 2.76 `
    -PublicConfiguration $PublicConfiguration `
    -PrivateConfiguration $PrivateConfiguration `
    -ForceUpdate

$VM | Update-AzureVM