param($Timer)

function ConvertTo-MountainTime {
    param(
        [DateTime]$date
    )
    $mountainStandardTimeId = "Mountain Standard Time"
    $mountainTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($mountainStandardTimeId)
    $mountainTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($date.ToUniversalTime(), $mountainTimeZone)
    return $mountainTime
}

# Ensure required modules are present and import them
$requiredModules = @('Az.Accounts', 'Az.Network')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module -Name $module -Scope CurrentUser -Force
    }
    Import-Module -Name $module -Force
}

# Initialize logging with time conversion
$startDateTime = ConvertTo-MountainTime -date (Get-Date)
Write-Output "Bastion deletion started at $startDateTime"

try {
    # Set Azure context
    Set-AzContext -Subscription $env:BASTION_SUB

    # Check if the Bastion host exists
    $bastionHost = Get-AzBastion -Name $env:BASTION_NAME -ResourceGroupName $env:BASTION_RG -ErrorAction SilentlyContinue

    if ($null -eq $bastionHost) {
        Write-Output "Bastion host '$($env:BASTION_NAME)' does not exist in resource group '$($env:BASTION_RG)'."
    }
    else {
        # Delete the Bastion host
        Write-Output "Deleting Bastion host '$($env:BASTION_NAME)'..."
        Remove-AzBastion -Name $env:BASTION_NAME -ResourceGroupName $env:BASTION_RG -Force

        Write-Output "Bastion host '$($env:BASTION_NAME)' deleted successfully."
    }
}
catch {
    $errorMessage = "Error deleting Bastion: $_"
    Write-Output $errorMessage
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [System.Net.HttpStatusCode]::InternalServerError
        Body = $errorMessage
    })
}
finally {
    $endDateTime = ConvertTo-MountainTime -date (Get-Date)
    Write-Output "Bastion deletion finished at $endDateTime"
}
