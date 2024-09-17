# Function to format table with colors
function Write-ColorTable {
    param (
        [string]$Title,
        [array]$Items,
        [string]$Color = "White"
    )

    Write-Host -ForegroundColor Yellow "=== $Title ==="
    foreach ($item in $Items) {
        Write-Host -ForegroundColor $Color $item
    }
    Write-Host "`n"
}

# Processor Information (including manufacturer)
$processorInfo = Get-WmiObject Win32_Processor | Select-Object Name, Manufacturer
$processorDetails = @()
foreach ($proc in $processorInfo) {
    $processorDetails += "$($proc.Manufacturer): $($proc.Name)"
}
Write-ColorTable -Title "Processor Information" -Items $processorDetails -Color Cyan

# GPU Information (including manufacturer)
$gpuInfo = Get-WmiObject Win32_VideoController | Select-Object Name, AdapterCompatibility
$gpuDetails = @()
foreach ($gpu in $gpuInfo) {
    $gpuDetails += "$($gpu.AdapterCompatibility): $($gpu.Name)"
}
Write-ColorTable -Title "Graphics Card(s)" -Items $gpuDetails -Color Green

# RAM Information (with slots and details)
$ramInfo = @()
$totalRam = [math]::round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$freeRam = [math]::round((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
$usedRam = [math]::round($totalRam - ($freeRam / 1024), 2)
$ramInfo += "Total: $totalRam GB, Used: $usedRam GB, Free: $([math]::round($freeRam / 1024, 2)) GB"

# Memory slot information
$ramSlots = Get-WmiObject Win32_PhysicalMemory | Select-Object Manufacturer, Capacity
foreach ($slot in $ramSlots) {
    $capacityGB = [math]::round($slot.Capacity / 1GB, 2)
    $ramInfo += "$($slot.Manufacturer): $capacityGB GB"
}
Write-ColorTable -Title "RAM Information" -Items $ramInfo -Color Magenta

# Disk Information (all available drives)
$disks = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }  # Only include fixed drives
foreach ($disk in $disks) {
    $totalDisk = [math]::round($disk.Size / 1GB, 2)
    $freeDisk = [math]::round($disk.FreeSpace / 1GB, 2)
    $usedDisk = [math]::round($totalDisk - $freeDisk, 2)
    $diskInfo = "Drive $($disk.DeviceID): Total: $totalDisk GB, Used: $usedDisk GB, Free: $freeDisk GB"
    Write-ColorTable -Title "Disk $($disk.DeviceID) Information" -Items @($diskInfo) -Color DarkCyan
}

# Motherboard Information (including manufacturer)
$motherboardInfo = Get-WmiObject Win32_BaseBoard | Select-Object Manufacturer, Product
$motherboardDetails = @()
foreach ($mb in $motherboardInfo) {
    $motherboardDetails += "$($mb.Manufacturer): $($mb.Product)"
}
Write-ColorTable -Title "Motherboard Information" -Items $motherboardDetails -Color Yellow

# BIOS Version
$bios = Get-WmiObject Win32_BIOS | Select-Object SMBIOSBIOSVersion, Manufacturer
$biosDetails = "$($bios.Manufacturer): Version $($bios.SMBIOSBIOSVersion)"
Write-ColorTable -Title "BIOS Version" -Items @($biosDetails) -Color Red

# Network Adapter Information (including manufacturer)
$networkAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object Description, Manufacturer
$networkDetails = @()
foreach ($adapter in $networkAdapters) {
    $networkDetails += "$($adapter.Manufacturer): $($adapter.Description)"
}
Write-ColorTable -Title "Network Adapter(s)" -Items $networkDetails -Color Blue

# System Uptime
$uptime = (Get-WmiObject Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - [System.Management.ManagementDateTimeConverter]::ToDateTime($uptime)
$uptimeInfo = "$($uptime.Days) Days, $($uptime.Hours) Hours, $($uptime.Minutes) Minutes"
Write-ColorTable -Title "System Uptime" -Items @($uptimeInfo) -Color White

# Operating System Information
$osInfo = Get-WmiObject Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture
$osDetails = @()
$osDetails += "OS: $($osInfo.Caption)"
$osDetails += "Version: $($osInfo.Version)"
$osDetails += "Architecture: $($osInfo.OSArchitecture)"
Write-ColorTable -Title "Operating System Information" -Items $osDetails -Color DarkYellow

# Virtualisation Information (if supported)
$virtualisationSupport = (Get-WmiObject Win32_Processor).VirtualizationFirmwareEnabled
$virtualisationDetails = if ($virtualisationSupport) { "Supported" } else { "Not Supported" }
Write-ColorTable -Title "Virtualisation Support" -Items @($virtualisationDetails) -Color DarkGreen

# Error handling for missing components
if (-not $processorInfo) {
    Write-Host -ForegroundColor Red "Processor information not available."
}

if (-not $gpuInfo) {
    Write-Host -ForegroundColor Red "Graphics card information not available."
}

if (-not $ramSlots) {
    Write-Host -ForegroundColor Red "RAM slot information not available."
}

if (-not $networkAdapters) {
    Write-Host -ForegroundColor Red "Network adapter information not available."
}

if (-not $uptime) {
    Write-Host -ForegroundColor Red "System uptime information not available."
}

# Function to get non-system installed software
function Get-InstalledSoftware {
    $softwareList = @()

    # Query both 32-bit and 64-bit installations (this key contains the list of software)
    $registryPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        $apps = Get-ItemProperty $path | Where-Object { $_.DisplayName -and $_.Publisher -and ($_.WindowsInstaller -ne 1) -and ($_.SystemComponent -ne 1) }

        foreach ($app in $apps) {
            $appDetails = "$($app.DisplayName) (Version: $($app.DisplayVersion), Publisher: $($app.Publisher))"
            $softwareList += $appDetails
        }
    }

    # Sort the software list alphabetically
    $softwareList = $softwareList | Sort-Object
    return $softwareList
}

# Retrieve non-system installed software
$installedSoftware = Get-InstalledSoftware
if ($installedSoftware.Count -gt 0) {
    Write-ColorTable -Title "Installed Third-Party Software" -Items $installedSoftware -Color White
} else {
    Write-Host -ForegroundColor Red "No third-party software found."
}
