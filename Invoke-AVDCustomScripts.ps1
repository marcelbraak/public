[CmdletBinding()]
param (
    [switch]$performHybridIntuneEnrollment,
    [switch]$skipDisableRDAgentBootLoader
)

function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    Add-Content -Path "C:\Windows\Temp\Invoke-AVDCustomScripts.log" -Value $logMessage
}


if (-not $skipDisableRDAgentBootLoader) {
    Write-Log "Stop and disable RDAgentBootLoader service..."
    ./Disable-RDAgentBootLoader.ps1
}

if ($performHybridIntuneEnrollment) {
    Write-Log "Performing Hybrid Intune Enrollment after stopping RDAgentBootLoader service..."
    # Call the Enroll-IntuneMDM.ps1 script to perform Hybrid Intune Enrollment
    .\Enroll-IntuneMDM.ps1
}