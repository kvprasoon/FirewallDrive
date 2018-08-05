using namespace Microsoft.PowerShell.SHiPS

[SHiPSProvider(UseCache = $false)]
class FirewallRoot : SHiPSDirectory
{
    # Default constructor
    FirewallRoot([string]$name):base($name)
    {
    }

    [object[]] GetChildItem()
    {        
        $Directions = @('Inbound','Outbound')
        $Output = $Directions | ForEach-Object -Process {
            [Direction]::new($_)
        }

        return $Output
    }
}

[SHiPSProvider(UseCache = $True)]
class Direction : SHiPSDirectory
{
    [string]$Direction

    Direction([string]$Name):base($Name)
    {
        $this.Direction = $Name
    }
    
    [object[]] GetChildItem ()
    {
        # Listing all Profiles regardless of current direction.
        $Profiles = Get-NetFirewallProfile | ForEach-Object -Process {
            [Profile]::new($_.Name,$_)
        }

        return $Profiles
    }
}

[SHiPSProvider(UseCache = $true)]
class Profile : SHiPSDirectory
{
    [object] $ProfileType
    [String] $Enabled
    [String] $LogAllowed
    [String] $LogMaxSizeKilobytes

    Profile([string]$name,$CurrentProfile):base($name)
    {
        $this.ProfileType         = $CurrentProfile
        $this.LogAllowed          = $CurrentProfile.LogAllowed
        $this.LogMaxSizeKilobytes = $CurrentProfile.LogMaxSizeKilobytes
        $this.Enabled             = $CurrentProfile.Enabled
    }
    
    [object[]] GetChildItem ()
    {
        $FirewallRules = Get-NetFirewallRule -AssociatedNetFirewallProfile $this.ProfileType | ForEach-Object -Process {
            [FirewallRule]::New($_.Name,$_)
        }

        return $FirewallRules
    }
}

[SHiPSProvider(UseCache = $true)]
class FirewallRule : SHiPSLeaf
{
    [String] $RuleDescription
    [String] $RuleProfile
    [String] $Name
    [String] $RuleState
    [String] $RuleStatus

    FirewallRule([string]$Name, [object]$Rule):base($name)
    {
        $this.Name            = $Name
        $this.RuleDescription = $Rule.Description
        $this.RuleProfile     = $Rule.Profile
        $this.RuleStatus      = $Rule.Status
        $this.RuleState       = 'Enabled'

        if( $Rule.Enabled -eq 'False' ){
            $this.RuleState = 'Disabled'
        }                
    }    
}
