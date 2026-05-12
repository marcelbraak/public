# Function to log messages with timestamps
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    Add-Content -Path "c:\windows\temp\intuneenrollment.log" -Value $logMessage
}

$EntraIDJoined = $false

while (-not $EntraIDJoined) {
        $eventlog = Get-WinEvent -LogName "Microsoft-Windows-User Device Registration/Admin" -FilterXPath "*[System[(EventID=306)]]" -MaxEvents 1 -ErrorAction SilentlyContinue

        if ($eventlog) {
            Write-Log "Event ID 306 detected in Event Viewer. Entra ID Enrollment successful."
            $EntraIDJoined = $true

            Write-Log "Addidng registry keys for MDM enrollment... and starting auto enrollment task scheduler task"

            $key = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\*'
            
            $keyinfo = Get-Item "HKLM:$key"
            $url = $keyinfo.name
            $url = $url.Split("\")[-1]
            $path = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$url"

            New-ItemProperty -LiteralPath $path -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc' -PropertyType String -Force -ea SilentlyContinue;

            New-ItemProperty -LiteralPath $path -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoft.com/TermsofUse.aspx' -PropertyType String -Force -ea SilentlyContinue;

            New-ItemProperty -LiteralPath $path -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoft.com/?portalAction=Compliance' -PropertyType String -Force -ea SilentlyContinue;

            # Start auto enroll
            Start-ScheduledTask -TaskName "Schedule created by enrollment client for automatically enrolling in MDM from AAD using device credential" -TaskPath "\Microsoft\Windows\EnterpriseMgmt\" -ErrorAction SilentlyContinue
            #C:\Windows\system32\deviceenroller.exe /c /AutoEnrollMDMUsingAADDeviceCredential

        } else {
            Write-Log "Event ID 306 not detected yet. Waiting for Entra ID Enrollment to complete..."
            Start-Sleep -Seconds 30
        }
}
