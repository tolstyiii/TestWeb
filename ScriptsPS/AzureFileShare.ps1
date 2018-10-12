function New-AzureFileShare {

    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName,

        [Parameter(Mandatory=$true)]
        [string]$ShareName
    )

    Process {
        $key1 = ((Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0]).value

        $storageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key1
        New-AzureStorageShare -Name $ShareName -Context $storageAccountContext
    }
}

New-AzureFileShare -ResourceGroupName "" -StorageAccountName "" -ShareName ""
