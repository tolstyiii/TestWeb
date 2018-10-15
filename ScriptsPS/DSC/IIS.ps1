Configuration WebServer {

    Import-DscResource -ModuleName "PSDesiredStateConfiguration"

    param(
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name
    )

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

Webserver -InstanceName "testweb-Server1"