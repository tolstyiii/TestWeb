Configuration WebServer {

    Import-DscResource -ModuleName "xPSDesiredStateConfiguration"

    param(
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$Name
    )

    Node $Name {
        WindowsFeature IIS {
            Ensure = "Present"
            Name = "Web-Server"
        }
        WindowsFeature IISManagementTools
        {
            Ensure = "Present"
            Name = "Web-Mgmt-Tools"
            DependsOn='[WindowsFeature]IIS'
        }
    }
}