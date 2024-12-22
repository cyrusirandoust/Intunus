# Printer Automatus - Printer Installation Automation Script

## Overview
Everyone struggles with printers; everyone with decent common sense in IT hates printers. This script is for those people—good people—who use Intune to make their lives easier.

This PowerShell script automates the installation of a network printer on a Windows system. It creates a TCP/IP port, installs the driver, adds the printer, and optionally sets it as the default printer.

---

## How It Works

### Variables to Update
Wherever you see `### CHANGE_ME ###`, you must customize the variables to suit your printer and environment:

- **`$PrinterName`**:
  - The name of the printer that will appear in applications like Word or Excel.
  - Example: `"SHARP BP-55C26 PCL6"`

- **`$IPAddress`**:
  - The network IP address of the printer.
  - If the TCP/IP port for this IP doesn’t exist, the script will create it. If it already exists, it will be reused.
  - Example: `"10.10.25.65"`

- **`$PortName`**:
  - The name prefix for the TCP/IP port creation.
  - Example: `"IP_$IPAddress"`

- **`$DriverName`**:
  - The exact name of the driver as defined in the `.inf` file provided by the driver vendor.
  - You must check the driver’s `.inf` file(s) to determine the correct name.
  - Example: `"SHARP BP-55C26 PCL6"`

- **`$DriverINFPath`**:
  - Optional. This specifies the path to the `.inf` file in the driver store.
  - If you know the exact location, provide it here for more efficient detection. Otherwise, the custom detection script will handle this.
  - Example: `"C:\Windows\System32\DriverStore\FileRepository\su3emfra.inf_amd64_9c3f2daa9b4d53c9\su3emfra.inf"`

Before using this script, ensure that all the necessary driver files are properly unpackaged from the driver installer you download. Often, these files come in the form of a `.exe` that extracts its contents during installation. You can extract the contents of such `.exe` files using tools like [7-Zip](https://www.7-zip.org/). Here's how to do it:

1. Right-click on the `.exe` file and select **7-Zip > Extract Here** or **Extract to <Folder Name>**.
2. Look for the extracted contents, including all necessary files like `.dll`, `.dl_`, `.cat`, and `.inf`.
3. Copy all these driver files into the same directory as the PowerShell script.

By placing the driver files alongside the script, the script can easily reference and install the required driver without issues. This ensures a smoother deployment process in Intune or any other environment.


---

## Detection Script for Intune
To ensure proper deployment through Intune, use the following detection script:

```powershell
$PrinterName = "SHARP BP-55C26 PCL6"

# Get the list of installed printers
$InstalledPrinters = Get-Printer

# Check if the printer is in the list
$PrinterInstalled = $InstalledPrinters.Name -contains $PrinterName

if ($PrinterInstalled) {
    Write-Host "Installed"
}
```

This script checks if the specified printer is installed on the device. Intune will mark the deployment as successful if this script returns "Installed."

---

## Intune Win32 App Packaging and Deployment

### Creating the `.intunewin` File
To package the script into an `.intunewin` file for deployment:

1. Download the [Microsoft Win32 Content Prep Tool](https://learn.microsoft.com/en-us/mem/intune/apps/apps-win32-app-management).
2. Use the following command to package your source folder:
   ```cmd
   .\IntuneWinAppUtil.exe -c "C:\Intune\source\printer-automatus" -s Install-SharpBP55C26Driver.ps1 -o "C:\Intune\output\printer-automatus"
    ```

   - `-c`: Path to the folder containing the script and supporting files.
   - `-s`: Name of the PowerShell script.
   - `-o`: Path to save the `.intunewin` package.

3. Upload the `.intunewin` file to Intune.

### App Configuration in Intune
1. **Install Behavior**:
   - Set to `System`.
2. **Detection Script**:
   - Use the detection script provided above.
3. **App Deployment Type**:
   - Choose `Windows 64-bit`.

For detailed screenshots, refer to the repository.

---

## Attribution
This script was authored by Cyrus Irandoust.

If you use or modify this script, please retain the author’s name and reference this GitHub repository to encourage improvements and collaboration.
