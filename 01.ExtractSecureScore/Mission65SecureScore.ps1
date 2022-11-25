# Feedback can be provided to Hans Hofkens (hans.hofkens@microsoft.com)

# Connect with the identity for which you would like to check Secure Score
# Only subscriptions with appropriate permissions will list a score.
Connect-AzAccount

# Set the CSV file to be created in the current folder
$MyCSVPath = [System.Environment]::CurrentDirectory + "\MySecureScores_" + $(get-date -f yyyy-MM-dd_HH-mm) +".csv"
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
