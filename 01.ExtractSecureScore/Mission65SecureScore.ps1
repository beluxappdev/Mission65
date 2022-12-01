# Feedback can be provided to Hans Hofkens (hans.hofkens@microsoft.com)

Write-Output "Starting Script...."

#Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

#Trusting Microsoft PowerShell Gallery
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation https://www.powershellgallery.com/api/v2


Write-Output "Installing PackageManagement Module"
install-module -name PackageManagement -scope CurrentUser -AllowClobber -Force

Write-Output "Updating PackageManagement Module"
update-module -Name PackageManagement


Write-Output "Installing PowerShellGet Module"
install-module -name PowerShellGet -scope CurrentUser -AllowClobber -Force -RequiredVersion 2.2.5

Write-Output "Updating PowerShellGet Module"
update-module -Name PowerShellGet 

Write-Output "Installing AZ Module"
Install-Module -Name az -scope currentUser -AllowClobber 

Write-Output "Updating AZ Module"
Update-Module -Name az 


# Connect with the identity for which you would like to check Secure Score
# Only subscriptions with appropriate permissions will list a score.
Connect-AzAccount

# Set the CSV file to be created in the Downloads folder
$MyCSVPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path + "\" + $(get-date -f yyyy-MM-dd_HH-mm) + ".csv"

# Get all tenants accessible by the current identity
$MyAzTenants = Get-AzTenant
foreach ($MyAzTenant in $MyAzTenants)
{
    Write-Output "Checking tenant: $MyAzTenant"
    # Get all subscriptions within the selected tenant
    $MyAzSubscriptions = Get-AzSubscription -TenantId $MyAzTenant

    foreach ($MyAzSubscription in $MyAzSubscriptions)
    {
        Write-Output "Checking subcription: $MyAzSubscription"
        Set-AzContext -Subscription $MyAzSubscription

        # Get the Secure Score & all controls for each subscription
        $MyAzSecureScore = Get-AzSecuritySecureScore
        $MyAzSecureScoreControls = Get-AzSecuritySecureScoreControl

        foreach ($MyAzSecureScoreControl in $MyAzSecureScoreControls)
        {
            # Create an array containing the Secure Score data
            $MyCSVRow = @( [pscustomobject]@{
                Date = (Get-Date).Date;
                TenantName = $MyAzTenant.Name;

                SubscriptionID = $MyAzSubscription.Id;
                SubscriptionName = $MyAzSubscription.Name;
                SubscriptionCurrentScore = $MyAzSecureScore.CurrentScore;
                SubscriptionMaxScore = $MyAzSecureScore.MaxScore;
                SubscriptionSecureScorePercentage = [math]::round(($MyAzSecureScore.Percentage * 100));
                SubscriptionWeight = $MyAzSecureScore.Weight;

                ControlName = $MyAzSecureScoreControl.Name;
                ControlDisplayName = $MyAzSecureScoreControl.DisplayName;
                ControlCurrentScore = $MyAzSecureScoreControl.CurrentScore;
                ControlMaxScore = $MyAzSecureScoreControl.MaxScore;
                ControlPercentage = [math]::round(($MyAzSecureScoreControl.Percentage * 100));
                ControlWeight = $MyAzSecureScoreControl.Weight;
                ControlHealthyResourceCount = $MyAzSecureScoreControl.HealthyResourceCount;
                ControlUnhealthyResourceCount = $MyAzSecureScoreControl.UnhealthyResourceCount;
                ControlNotApplicableResourceCount = $MyAzSecureScoreControl.NotApplicableResourceCount
            } )

            # Append the Secure Score to the CSV file
            $MyCSVRow | Export-Csv $MyCSVPath -Append
        }
    }
}
