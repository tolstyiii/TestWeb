configuration TestConfig
{
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

    Node Server3
    {
        WindowsFeature IIS
        {
            Ensure               = 'Present'
            Name                 = 'Web-Server'
            IncludeAllSubFeature = $true
        }
    } 

    Node NotWebServer
    {
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }
}