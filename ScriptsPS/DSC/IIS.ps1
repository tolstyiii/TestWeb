Configuration WebServer {

    param(
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name
    )

    Import-DscResource -ModuleName "PSDesiredStateConfiguration"

    Node $Name {
        WindowsFeature IIS {
            Ensure = "Present"
            Name = "Web-Server"
        }
        WindowsFeature IISManagementTools {
            Ensure = "Present"
            Name = "Web-Mgmt-Tools"
            DependsOn='[WindowsFeature]IIS'
        }
    }
}

Webserver -Name "testweb-Server1","testweb-Server2" -OutputPath "d:\Git\ScriptsPS\DSC\"