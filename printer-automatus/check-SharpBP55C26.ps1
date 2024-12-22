$PrinterName = "SHARP BP-55C26 PCL6"

# Get the list of installed printers
$InstalledPrinters = Get-Printer

# Check if the printer is in the list
$PrinterInstalled = $InstalledPrinters.Name -contains $PrinterName

if ($PrinterInstalled) {
    Write-Host "Installed"
}
