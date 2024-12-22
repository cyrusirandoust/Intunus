$ErrorActionPreference = "Stop"

# Variables
$PrinterName = "SHARP BP-55C26 PCL6"    ### CHANGE_ME ###
$IPAddress = "10.10.25.65"              ### CHANGE_ME ###
$PortName = "IP_$IPAddress"             
$DriverName = "SHARP BP-55C26 PCL6"     ### CHANGE_ME ###
$DriverINFPath = "C:\Windows\System32\DriverStore\FileRepository\su3emfra.inf_amd64_9c3f2daa9b4d53c9\su3emfra.inf"  ### CHANGE_ME ###

# Set up logging
try {
    $ProgramDataPath = $env:ProgramData
    $PrintusAutomatusFolderPath = Join-Path -Path $ProgramDataPath -ChildPath "PrintusAutomatus"    ### CHANGE_ME ###
    
    if (-not (Test-Path -Path $PrintusAutomatusFolderPath)) {
        New-Item -ItemType Directory -Path $PrintusAutomatusFolderPath | Out-Null
    }
}
catch {
    $PrintusAutomatusFolderPath = Join-Path -Path "C:\Users\Public\Documents" -ChildPath "PrintusAutomatus" ### CHANGE_ME ###
}

$LogFile = Join-Path -Path $PrintusAutomatusFolderPath -ChildPath "SharpBP-55C26DriverInstallLog.txt"   ### CHANGE_ME ###

# Check if the driver is already installed
try {
    $InstalledDriver = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
}
catch {
    $InstalledDriver = $null
}

if ($InstalledDriver) {
    "Driver '$DriverName' is already installed. Skipping driver installation." | Out-File $LogFile -Append
} else {
    try {
        if (Test-Path -Path $DriverINFPath) {
            "Installing driver '$DriverName' using driver package at '$DriverINFPath'..." | Out-File $LogFile -Append
            & "$env:WINDIR\sysnative\pnputil.exe" /add-driver "$DriverINFPath" /install | Out-File $LogFile -Append
            Add-PrinterDriver -Name $DriverName -InfPath $DriverINFPath
        } else {
            try {
                "Driver package not found at '$DriverINFPath'. Installing from package instead.." | Out-File $LogFile -Append
                $DriverFolder = Get-Location
                $DriverINF = (Get-ChildItem -Path $DriverFolder -Filter "*.inf" -Recurse | Select-Object -First 1).FullName
                
                & "$env:WINDIR\sysnative\pnputil.exe" /add-driver "$DriverINF" /install | Out-File $LogFile -Append
                Add-PrinterDriver -Name $DriverName -InfPath $DriverINF
            }
            catch {
                "Failed to install driver from '$DriverINF' from package. Attempting to install from DriverStore..." | Out-File $LogFile -Append
                try {
                    if (Test-Path -Path $DriverINFPath) {
                        "Installing driver '$DriverName' using driver package at '$DriverINFPath'..." | Out-File $LogFile -Append
                        & "$env:WINDIR\sysnative\pnputil.exe" /add-driver "$DriverINFPath" /install | Out-File $LogFile -Append
                        Add-PrinterDriver -Name $DriverName -InfPath $DriverINFPath
                    } else {
                        "Driver package not found at '$DriverINFPath' after attempting installation from package." | Out-File $LogFile -Append
                    }
                }
                catch {
                    $_.Exception.Message | Out-File $LogFile -Append
                    throw $_
                }
            }
        }
    }
    catch {
        "Failed to install driver '$DriverName'... tried all..." | Out-File $LogFile -Append
        $_.Exception.Message | Out-File $LogFile -Append
        throw $_
    }
}

# Create a new TCP/IP port
try {
    "Creating TCP/IP port '$PortName'..." | Out-File $LogFile -Append
    $port = ([wmiclass]"Win32_TCPIPPrinterPort").CreateInstance()
    $port.HostAddress = $IPAddress
    $port.Name = $PortName
    $port.Protocol = 1
    $port.Put()
}
catch {
    "Failed create tcp/ip port '$PortName'..." | Out-File $LogFile -Append
    $_.Exception.Message | Out-File $LogFile -Append
    throw $_
}

# Create the printer object
try {
    "Creating printer '$PrinterName' using driver '$DriverName' on port '$PortName'..." | Out-File $LogFile -Append
    Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName
    "Printer '$PrinterName' created successfully." | Out-File $LogFile -Append
} catch {
    $ErrorDetails = $_.Exception.Message
    "Failed to create printer '$PrinterName'. HRESULT: $($ErrorDetails)" | Out-File $LogFile -Append
    throw $_
}

# Set the printer as the default printer
try {
    "Setting '$PrinterName' as default printer..." | Out-File $LogFile -Append
    (New-Object -ComObject WScript.Network).SetDefaultPrinter($PrinterName)
    "Default printer set to '$PrinterName'." | Out-File $LogFile -Append
} catch {
    $ErrorDetails = $_.Exception.Message
    "Failed to set default printer '$PrinterName'. HRESULT: $($ErrorDetails)" | Out-File $LogFile -Append
    throw $_
}
