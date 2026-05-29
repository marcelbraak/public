function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    Add-Content -Path "C:\Windows\Temp\Disable-RDAgentBootLoader.log" -Value $logMessage
}

# Registry path and value name
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows Azure\RDAgentBootloadHandler"
$valueName    = "isEnabling"

# Delay between checks (in seconds)
$delaySeconds = 60

Write-Log "Monitoring registry value '$valueName' at '$registryPath'..."

while ($true) {
    try {
        # Read the registry value
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName

        Write-Log "Current value: $currentValue"

        # Check if the value is "False"
        if ($currentValue -eq "False") {
            Write-Log "Value is 'False'. Stopping RDAgentBootLoader service..."

            powershell -ExecutionPolicy Unrestricted -Command "Stop-Service -Name RDAgentBootLoader -Force"

            Write-Log "Service stop command executed."
            break
        } elseif ($currentValue -eq "True") {
            Write-Log "Value is 'True'. RDAgentBootLoader service still registering with AVD Hoost Pool. Will check again in $delaySeconds seconds."
        } 
    }
    catch {
        Write-Warning "Failed to read registry value. $_"
        Write-Log "'$registryPath\$valueName' does not exist yet. Will check again in $delaySeconds seconds."
    }

    # Wait before next check
    Start-Sleep -Seconds $delaySeconds
}