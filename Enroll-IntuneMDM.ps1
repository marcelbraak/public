<#
.SYNOPSIS
    Enroll device into Intune MDM after it's joined to Entra ID
.DESCRIPTION
    Enroll device into Intune MDM after it's joined to Entra ID by adding the required registry keys and starting the auto enrollment scheduled task.
.NOTES
    
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Enroll-IntuneMDM.ps1
    Enroll device into Intune MDM after it's joined to Entra ID
#>


# Function to log messages with timestamps
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    Add-Content -Path "C:\Windows\Temp\MCRL_Enroll-IntuneMDM.log" -Value $logMessage
}

function Start-IntuneMDMEnrollment {
    Write-Log "Starting Intune enrollment process..."

    Write-Log "Adding registry keys for MDM enrollment... and starting auto enrollment task scheduler task"

            $key = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\*'
            
            $keyinfo = Get-Item "HKLM:$key"
            $url = $keyinfo.name
            $url = $url.Split("\")[-1]
            $path = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$url"

            Write-Log "Adding registry key for MdmEnrollmentUrl, MdmTermsOfUseUrl and MdmComplianceUrl"
            New-ItemProperty -LiteralPath $path -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc' -PropertyType String -Force -ea SilentlyContinue;
            New-ItemProperty -LiteralPath $path -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoft.com/TermsofUse.aspx' -PropertyType String -Force -ea SilentlyContinue;
            New-ItemProperty -LiteralPath $path -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoft.com/?portalAction=Compliance' -PropertyType String -Force -ea SilentlyContinue;

            Start-Sleep -Seconds 5

            # Start auto enroll
            Start-ScheduledTask -TaskName "Schedule created by enrollment client for automatically enrolling in MDM from AAD using AAD device credential" -TaskPath "\Microsoft\Windows\EnterpriseMgmt\"
            #C:\Windows\system32\deviceenroller.exe /c /AutoEnrollMDMUsingAADDeviceCredential
}   


$EntraIDJoined = $false


while (-not $EntraIDJoined) {
        $eventlog = Get-WinEvent -LogName "Microsoft-Windows-User Device Registration/Admin" -FilterXPath "*[System[(EventID=306)]]" -MaxEvents 1 -ErrorAction SilentlyContinue

        if ($eventlog) {
            Write-Log "Event ID 306 detected in Event Viewer. Entra ID Enrollment successful."
            $EntraIDJoined = $true

            Start-IntuneMDMEnrollment

        } else {
            Write-Log "Event ID 306 not detected yet. Waiting for Entra ID Enrollment to complete..."
            Write-Log "Starting scheduled task (Automatic-Device-Join) to speed up the process... Checking again in 60 seconds."
            Start-ScheduledTask -TaskName "Automatic-Device-Join" -TaskPath "\Microsoft\Windows\Workplace Join\"
            Start-Sleep -Seconds 60 
        }
}
