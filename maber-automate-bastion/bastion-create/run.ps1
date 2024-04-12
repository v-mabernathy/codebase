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
Write-Output "Deployment started at $startDateTime"

try {
    # Validate environment variables
    $envVars = @('BASTION_VNET_NAME', 'BASTION_VNET_RG', 'BASTION_PIP_NAME', 'BASTION_PIP_RG', 'BASTION_NAME', 'BASTION_RG', 'BASTION_SUB')
    foreach ($var in $envVars) {
        if (-not (Get-Item -Path "env:$var" -ErrorAction SilentlyContinue)) {
            Write-Error "The required environmental variable '$var' is missing."
            exit 1
        }
    }

    # Set Azure context
    Set-AzContext -Subscription $env:BASTION_SUB

    # Get resources
    $vNet = Get-AzVirtualNetwork -Name $env:BASTION_VNET_NAME -ResourceGroupName $env:BASTION_VNET_RG
    $pip = Get-AzPublicIpAddress -Name $env:BASTION_PIP_NAME -ResourceGroupName $env:BASTION_PIP_RG

    # Deploy Bastion host
    $job = New-AzBastion -Name $env:BASTION_NAME -ResourceGroupName $env:BASTION_RG -VirtualNetwork $vNet -PublicIpAddress $pip -EnableTunneling $true -AsJob
} catch {
    Write-Output "Error encountered: $_"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [System.Net.HttpStatusCode]::InternalServerError
        Body = "Error deploying Bastion: $_"
    })
} finally {
    $endDateTime = ConvertTo-MountainTime -date (Get-Date)
    Write-Output "Deployment finished at $endDateTime"
}
