[CmdletBinding()]
param (
    [switch]$performHybridIntuneEnrollment, # Pass this switch if you want to perform Hybrid Intune Enrollment after stopping RDAgentBootLoader service. This will call the Enroll-IntuneMDM.ps1 script.
    [switch]$skipDisableRDAgentBootLoader   # By default the script will disable RDAgentBootLoader service, but you can choose to skip this step if needed
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