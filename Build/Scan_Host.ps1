<#
.SYNOPSIS
  Tool to Scan a remote computer for information.
.DESCRIPTION
  This tool is a sub component of PUSH_2.0, and can be used to scan a computer for hardware, software, user, file, etc. information.
.PARAMETER ComputerName
  The name of the computer to scan. 
.INPUTS
  A hostname to scan
.OUTPUTS
  A GUI window with information about the computer.
.NOTES
  Version:        1.0.8 [Nasty Networks]
  Author:         Kyle Ketchell, Matt Smith
  Creation Date:  May 29, 2022
.EXAMPLE
  Scan_Host.ps1 ETS_Test_Computer
#>

param(                                                                    # Parameters Ref: Microsoft, Parameters
  [String]$Hostname=$env:COMPUTERNAME,                                    #
  [Parameter(ParameterSetName = "GUI")][Switch]$light=$false,             # light (light mode) (loser mode)
  [Parameter()][Alias("dir")][String]$Location="\\software.engr.colostate.edu\software\ENS\Push_2.0",
  [Parameter()][String]$Configure="\\software.engr.colostate.edu\software\ENS\Push_2.0\Configuration.xml", # You can specify no parameters!
  [Parameter()][String]$ColorScheme="Dark",                               #
  [Parameter()][String]$DesignScheme="Original"                           #
)                                                                         #

###########################################################################
# Documentation: Import necessary things                                  #
# These are important and need to be in this file or something idk        #
###########################################################################
Add-Type -AssemblyName System.Windows.Forms
$global:WORKING_DIR = (Get-Location).Path

Set-Location $Location
if (Get-Module Scan_Host) { Remove-Module Scan_Host }
Import-Module .\Build\Scan_Host.psm1

###########################################################################
# Documentation: Parameter settings (as of now)                           #
# I'm putting this here partially because I don't know where to put it    #
# and partially because I don't want to scroll from  bottom to param all the time #
###########################################################################
Import-Module .\Build\Push_Config_Manager.psm1                            # Import the Push Configuration Manager
$Config = Get-PUSH_Configuration $Configure -ColorScheme $ColorScheme -Design $DesignScheme -Application "Scan_Host" # Get the configuration settings
if ($light) { $Config = Get-PUSH_Configuration $Configure -ColorScheme "Light" -Design "Original" -Application "Scan_Host" } # Get the light configuration settings


###########################################################################
# Documentation: Global Variables (Stolen from PUSH)                      #
# These are variables that everything should be able to access            #
###########################################################################
$global:BackgroundColor = $Config.ColorScheme.Background                  # an Argb color (Alpha, Red, Green, Blue)
$global:ForegroundColor = $Config.ColorScheme.Foreground                  # terminal.sexy can help you generate some great color schemes.
#$global:ToolStripBGColor = $Config.ColorScheme.ToolStripBackground        # there's no ts in Scan_host (yet...)
#$global:ToolStripHoverColor = $Config.ColorScheme.ToolStripHover          #
#$global:DoneLabelColor = $Config.ColorScheme.Success                      # 
$global:FlatStyle = $Config.Design.FlatStyle                              #
$global:BorderStyle = $Config.Design.BorderStyle                          #
$global:FontSettings = ($Config.Design.FontName, $Config.Design.FontSize) #
                                                                          #
###########################################################################

# stop Scan_Host if there is no connection to the computer
if (-not (Test-Connection $Hostname -quiet)) {log "Comptuer not found"; [System.Windows.Forms.MessageBox]::Show("Computer not found", "Ruh roh, Raggy"); exit}
try {
  Invoke-WmiMethod -ComputerName $Hostname -Class Win32_Process 'Create' "powershell.exe /c Enable-PSRemoting -SkipNetworkProfileCheck -Force"
  Start-Sleep 1
  Get-CimInstance -ComputerName $Hostname -ClassName Win32_ComputerSystem
} catch {
  log "Another issue occured: the computer is online, but we're unable to enable psremoting on it." 0
  [System.Windows.Forms.MessageBox]::Show("Computer appears to be online, but we're unable to scan it.")
  exit
}

###########################################################################
# Documentation: GUI Form                                                 #
# Display a form of all of this information, as well as a button to get   #
# more information.                                                       #
###########################################################################
#Dark mode will be released in v1.0.8 [Dusty DarkMode]
$Form                       = New-Object System.Windows.Forms.Form
$Form.AutoSize              = $true
$Form.Text                  = "$($Config.About.Name) $($Config.About.Version) - $($Config.About.Nickname)"
# GUI options based on configuration
$Form.Font                  = New-Object System.Drawing.Font($global:FontSettings)
$Form.TopMost = $true
$Form.Add_MouseEnter({ $Form.TopMost = $false })
$Form.BackColor             = $global:BackgroundColor
$Form.ForeColor             = $global:ForegroundColor
$Form.Icon = $Config.Design.Scan_Host_Icon

###########################################################################
# Documentation: Processor Info Label                                     #
# Display a form of all of this information, as well as a button to get   #
# more information.                                                       #
###########################################################################
$ProcessorLabel             = New-Object System.Windows.Forms.Label       #
$ProcessorLabel.Size        = New-Object System.Drawing.Size(100,23)      #
$ProcessorLabel.Location    = New-Object System.Drawing.Point(10,10)      #
$ProcessorLabel.Text        = "Processor"                                 #
# GUI options based on configuration                                      #
$ProcessorLabel.Font        = New-Object System.Drawing.Font($global:FontSettings) #
$ProcessorLabel.BackColor   = $global:BackgroundColor                     #
$ProcessorLabel.ForeColor   = $global:ForegroundColor                     #
                                                                          #
#######################################################################   #
# Documentation: Processor Info Box                                   #   #
# Box that displays all the processor info                            #   #
#######################################################################   #
$ProcessorInfoBox           = New-Object System.Windows.Forms.TextBox #   #
$ProcessorInfoBox.Size      = New-Object System.Drawing.Size(300,210) #   #
$ProcessorInfoBox.Location  = New-Object System.Drawing.Point(10,33)  #   #
$ProcessorInfoBox.ReadOnly  = $true                                   #   #
$ProcessorInfoBox.Multiline = $true                                   #   #
$ProcessorInfoBox.ScrollBars = "Vertical"                             #   #
$PI = Get-ProcessorInfo $Hostname                                     #   #
$ProcessorInfoBox.Text      = ""                                      #   #   
$ProcessorInfoBox.AppendText("$($PI.Name)`r`n")                       #   #
$ProcessorInfoBox.AppendText("$($PI.Speed)`r`n")                      #   #
$ProcessorInfoBox.AppendText("$($PI.Cores) Cores`r`n")                #   #
$ProcessorInfoBox.AppendText("$($PI.LogicalProcessors) Logical Processors`r`n") #
# GUI options based on configuration                                  #   #
$ProcessorInfoBox.Font      = New-Object System.Drawing.Font($global:FontSettings) #
$ProcessorInfoBox.BackColor = $global:BackgroundColor                 #   #
$ProcessorInfoBox.ForeColor = $global:ForegroundColor                 #   #
#######################################################################   #
                                                                          #
###########################################################################
# Documentation: Hardware Information Label                               #
# Box that displays all the hardware information about the computer       #
#                                                                         #
###########################################################################
$HardwareLabel              = New-Object System.Windows.Forms.Label       #
$HardwareLabel.Size         = New-Object System.Drawing.Size(100,23)      #
$HardwareLabel.Location     = New-Object System.Drawing.Point(315,10)     #
$HardwareLabel.Text         = "Hardware"                                  #
# GUI options based on configuration                                      #
$HardwareLabel.Font         = New-Object System.Drawing.Font($global:FontSettings)
$HardwareLabel.BackColor    = $global:BackgroundColor                     #
$HardwareLabel.ForeColor    = $global:ForegroundColor                     #
                                                                          #
#######################################################################   #
# Documentation: Hardware Info Box                                    #   #
# Box that displays all the hardware information                      #   #
#######################################################################   #
$HardwareInfoBox            = New-Object System.Windows.Forms.TextBox #   #
$HardwareInfoBox.Size       = New-Object System.Drawing.Size(300,210) #   #
$HardwareInfoBox.Location   = New-Object System.Drawing.Point(315,33) #   #
$HardwareInfoBox.ReadOnly   = $true                                   #   #
$HardwareInfoBox.Multiline  = $true                                   #   #
$HardwareInfoBox.ScrollBars = 'Vertical'                              #   #
$HW = Get-HardwareInfo $Hostname                                      #   #
$HardwareInfoBox.Text       = ""                                      #   #
$HardwareInfoBox.AppendText("$($HW.Name)`r`n")                        #   #
if ($HW.Name -ne $HW.DNSName) { $HardwareInfoBox.AppendText("Second Name: $($HW.DNSName)`r`n") }
if ($HW.OnDomain) { $HardwareInfoBox.AppendText("Domain: $($HW.Domain)`r`n") }
else { $HardwareInfoBox.AppendText("Workgroup: $($HW.Workgroup)`r`n") }   #
$HardwareInfoBox.AppendText("Make: $($HW.Manufacturer)`r`n")          #   #
$HardwareInfoBox.AppendText("Model: $($HW.Model)`r`n")                #   #
$HardwareInfoBox.AppendText("Serial: $($HW.Serial)`r`n")              #   #
$HardwareInfoBox.AppendText("Installed RAM: $($HW.RAM)`r`n")          #   #
# GUI options based on configuration                                  #   #
$HardwareInfoBox.Font       = New-Object System.Drawing.Font($global:FontSettings)
$HardwareInfoBox.BackColor  = $global:BackgroundColor                 #   #
$HardwareInfoBox.ForeColor  = $global:ForegroundColor                 #   #
#######################################################################   #
                                                                          #
###########################################################################
# Documentation: Software Information Label                               #
# Label for the Software Info Box                                         #
#                                                                         #
###########################################################################
$SoftwareLabel              = New-Object System.Windows.Forms.Label       #
$SoftwareLabel.Size         = New-Object System.Drawing.Size(130,23)      #
$SoftwareLabel.Location     = New-Object System.Drawing.Point(620,10)     #
$SoftwareLabel.Text         = "Operating System"                          # 
# GUI options based on configuration                                      #
$SoftwareLabel.Font         = New-Object System.Drawing.Font($global:FontSettings)
$SoftwareLabel.BackColor    = $global:BackgroundColor                     #
$SoftwareLabel.ForeColor    = $global:ForegroundColor                     #
                                                                          #
#######################################################################   #
# Documentation: Software Info Box                                    #   #
# Box that displays all the OS information                            #   #
#######################################################################   #
$SoftwareInfoBox            = New-Object System.Windows.Forms.TextBox #   #
$SoftwareInfoBox.Size       = New-Object System.Drawing.Size(300,210) #   #
$SoftwareInfoBox.Location   = New-Object System.Drawing.Point(620,33) #   #
$SoftwareInfoBox.ReadOnly   = $true                                   #   #
$SoftwareInfoBox.Multiline  = $true                                   #   #
$SoftwareInfoBox.ScrollBars = 'Vertical'                              #   #
$SI = Get-SoftwareInfo $Hostname                                      #   #
$SoftwareInfoBox.Text = ""                                            #   #
$SoftwareInfoBox.AppendText("$($SI.Caption)`r`n")                     #   #
$SoftwareInfoBox.AppendText("$($SI.Version)`r`n")                     #   #
switch ($SI.Version) {                                                #   #
  '10.0.19044' { $SoftwareInfoBox.AppendText("21H2`r`n") }            #   #
  '10.0.19043' { $SoftwareInfoBox.AppendText("21H1`r`n") }            #   #
  '10.0.19042' { $SoftwareInfoBox.AppendText("20H2`r`n") }            #   #
  '10.0.19041' { $SoftwareInfoBox.AppendText("2004`r`n") }            #   #
  '10.0.18363' { $SoftwareInfoBox.AppendText("1909`r`n") }            #   #
  '10.0.18362' { $SoftwareInfoBox.AppendText("1903`r`n") }            #   #
  '10.0.17763' { $SoftwareInfoBox.AppendText("1809`r`n") }            #   #
  '10.0.17134' { $SoftwareInfoBox.AppendText("1803`r`n") }            #   #
  '10.0.16299' { $SoftwareInfoBox.AppendText("1709`r`n") }            #   #
  '10.0.14393' { $SoftwareInfoBox.AppendText("1607`r`n") }            #   #
}                                                                     #   #
$SoftwareInfoBox.AppendText("It is currently: $($SI.Time)`r`n")       #   #
$SoftwareInfoBox.AppendText("Boot time: $($SI.BootTime)`r`n")         #   #
$SoftwareInfoBox.AppendText("Current up-time: $($SI.Uptime)`r`n")     #   #
$SoftwareInfoBox.AppendText("OS Install Date: $($SI.InstallDate)`r`n")#   #
$SoftwareInfoBox.AppendText("Registered to: $($SI.RUser), $($SI.ROrganization)`r`n")
$SoftwareInfoBox.AppendText("$($SI.Users)`r`n")                       #   #
# GUI options based on configuration                                  #   #
$SoftwareInfoBox.Font       = New-Object System.Drawing.Font($global:FontSettings)
$SoftwareInfoBox.BackColor  = $global:BackgroundColor                 #   #
$SoftwareInfoBox.ForeColor  = $global:ForegroundColor                 #   #
#######################################################################   #
                                                                          #
###########################################################################
# Documentation: Disk/Drive Information Label                             #
# Label for the Disk drive information box                                #
#                                                                         #
###########################################################################
$DiskLabel                  = New-Object System.Windows.Forms.Label       #
$DiskLabel.Size             = New-Object System.Drawing.Size(100,23)      #
$DiskLabel.Location         = New-Object System.Drawing.Point(925,10)     #
$DiskLabel.Text             = "Disks"                                     #
# GUI options based on configuration                                      #
$DiskLabel.Font             = New-Object System.Drawing.Font($global:FontSettings)
$DiskLabel.BackColor        = $global:BackgroundColor                     #
$DiskLabel.ForeColor        = $global:ForegroundColor                     #
                                                                          #
$DiskInfoBox                = New-Object System.Windows.Forms.TextBox     #
$DiskInfoBox.Size           = New-Object System.Drawing.Size(300,210) # Needs to be changed because SansSkrit changes text size
# GUI options based on configuration                                      #
$DiskInfoBox.Font           = New-Object System.Drawing.Font($global:FontSettings)
$DiskInfoBox.BackColor      = $global:BackgroundColor                     #
$DiskInfoBox.ForeColor      = $global:ForegroundColor                     # i got lazy ill finish it at work later
                                                                          #
$DiskInfoBox.Location       = New-Object System.Drawing.Point(925,33)     #
$DiskInfoBox.ReadOnly       = $true                                       #
$DiskInfoBox.Multiline      = $true                                       #
$DiskInfoBox.ScrollBars     = 'Vertical'                                  #
$DI                         = Get-DiskInfo $Hostname                      #
$DiskInfoBox.Text           = ""                                          #
$DI | ForEach-Object {                                                    #
  if ($_.DeviceName) {                                                    # 
    $DiskInfoBox.AppendText("$($_.DeviceName) $($_.VolumeName)`r`n")      #
    $DiskInfoBox.AppendText("  $($_.UsedSpace) Used, $($_.PartitionSize) Available`r`n")
    $DiskInfoBox.AppendText("  $($_.FreeSpace) free`r`n")                 #
    $DiskInfoBox.AppendText("  $($_.FileSystem)`r`n")                     #
    $DiskInfoBox.AppendText("Physical Disk Information: $($_.DiskModel)`r`n")
    $DiskInfoBox.AppendText("  $($_.TotalDiskSize) Total Size of Disk`r`n")
    $DiskInfoBox.AppendText("  $($_.MediaType)`r`n")                      #
#    $DiskInfoBox.AppendText("  $($_.DiskSerial)`n")                      #
    $DiskInfoBox.AppendText("`r`n")                                       #
  }                                                                       #
}                                                                         #

$NetworkLabel                  = New-Object System.Windows.Forms.Label       #
$NetworkLabel.Size             = New-Object System.Drawing.Size(100,23)      #
$NetworkLabel.Location         = New-Object System.Drawing.Point(315,245)     #
$NetworkLabel.Text             = "Network Card"                                     #
# GUI options based on configuration                                      #
$NetworkLabel.Font             = New-Object System.Drawing.Font($global:FontSettings)
$NetworkLabel.BackColor        = $global:BackgroundColor                     #
$NetworkLabel.ForeColor        = $global:ForegroundColor                     #
                                                                          #
$NetworkInfoBox                = New-Object System.Windows.Forms.TextBox     #
$NetworkInfoBox.Size           = New-Object System.Drawing.Size(300,210) # Needs to be changed because SansSkrit changes text size
# GUI options based on configuration                                      #
$NetworkInfoBox.Font           = New-Object System.Drawing.Font($global:FontSettings)
$NetworkInfoBox.BackColor      = $global:BackgroundColor                     #
$NetworkInfoBox.ForeColor      = $global:ForegroundColor                     # i got lazy ill finish it at work later
                                                                          #
$NetworkInfoBox.Location       = New-Object System.Drawing.Point(315,268)     #
$NetworkInfoBox.ReadOnly       = $true                                       #
$NetworkInfoBox.Multiline      = $true                                       #
$NetworkInfoBox.ScrollBars     = 'Vertical'                                  #
$NI                         = Get-NetworkInfo $Hostname                      #
$NetworkInfoBox.Text           = ""                                          #
$NetworkInfoBox.AppendText("Name: $($NI.Name)`r`n")
#$NetworkInfoBox.AppendText("Manufacturer: $($NI.Manufacturer)`r`n")
$NetworkInfoBox.AppendText("IP: $($NI.IPAddress)`r`n")
$NetworkInfoBox.AppendText("Subnet: $($NI.IPSubnet)`r`n")
$NetworkInfoBox.AppendText("Gateway: $($NI.DefaultIPGateway)`r`n")
$NetworkInfoBox.AppendText("MAC Address: $($NI.MACAddress)`r`n")
$NetworkInfoBox.AppendText("Adapter Type: $($NI.AdapterType)`r`n")
$NetworkInfoBox.AppendText("Speed: $($NI.Speed)`r`n")

if ($NI.DHCPEnabled) {
  $NetworkInfoBox.AppendText("DHCP Server: $($NI.DHCPServer)`r`n")
  $NetworkInfoBox.AppendText("Lease Obtained: $($NI.DHCPLeaseObtained)`r`n")
  $NetworkInfoBox.AppendText("Lease Expires: $($NI.DHCPLeaseExpires)`r`n")
}

$NetworkInfoBox.AppendText("DNS Hostname: $($NI.DNSHostName)`r`n")
$NetworkInfoBox.AppendText("DNS Domain: $($NI.DNSDomain)`r`n")
$NetworkInfoBox.AppendText("Last Reset: $($NI.TimeOfLastReset)`r`n")

<#
$UserLabel                  = New-Object System.Windows.Forms.Label       #
$UserLabel.Size             = New-Object System.Drawing.Size(100,23)      #
$UserLabel.Location         = New-Object System.Drawing.Point(10,277)     #
$UserLabel.Text             = "Disks"                                     #
# GUI options based on configuration                                      #
$UserLabel.Font             = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
$UserLabel.BackColor        = $Config.ColorScheme.Background              #
$UserLabel.ForeColor        = $Config.ColorScheme.Foreground              #
                                                                          #
$UserInfoBox                = New-Object System.Windows.Forms.ListBox     #
$UserInfoBox.Size           = New-Object System.Drawing.Size(300,210)     # Needs to be changed because SansSkrit changes text size
# GUI options based on configuration                                      #
$UserInfoBox.Font           = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
$UserInfoBox.BackColor      = $Config.ColorScheme.Background              #
$UserInfoBox.ForeColor      = $Config.ColorScheme.Foreground              # i got lazy ill finish it at work later
$UserInfoBox.Location       = New-Object System.Drawing.Point(10,300)     #
$UserInfoBox.ScrollBars     = 'Vertical'                                  #>
                                                                          #
$MoreInfoButton             = New-Object System.Windows.Forms.Button      #
#$MoreInfoButton.Size        = New-Object System.Drawing.Size(130,23) # not sure if they were sized manually for a reason but we're trying autosizing
$MoreInfoButton.AutoSize    = $true                                       #
$MoreInfoButton.Location    = New-Object System.Drawing.Point(10, 245)    #
$MoreInfoButton.Text        = "More Information"                          #
# GUI options based on configuration                                      #
$MoreInfoButton.Font        = New-Object System.Drawing.Font($global:FontSettings)
$MoreInfoButton.BackColor   = $global:BackgroundColor                     #
$MoreInfoButton.ForeColor   = $global:ForegroundColor                     #
$MoreInfoButton.FlatStyle   = $global:FlatStyle                           #
                                                                          #
$MoreInfoButton.Add_Click({                                               #
  Start-Process powershell -ArgumentList "-NoExit",                       #
    "Write-Host 'Win32_ComputerSystem'; Get-CimInstance Win32_ComputerSystem -ComputerName $Hostname | Format-List *;", 
    "Write-Host 'Win32_OperatingSystem'; Get-CimInstance Win32_OperatingSystem -ComputerName $Hostname | Format-List *;",
    "Write-Host 'Win32_LogicalDisk'; Get-CimInstance Win32_LogicalDisk -ComputerName $Hostname | Format-List *;",
    "Write-Host 'Win32_DiskDrive'; Get-CimInstance Win32_DiskDrive -ComputerName $Hostname | Format-List *;",
    "Write-Host 'Win32_Processor'; Get-CimInstance Win32_Processor -ComputerName $Hostname | Format-List *;",
    "Write-Host 'Win32_Processes'; Get-CimInstance Win32_Process -ComputerName $Hostname;",
    "Write-Host 'Win32_NetworkAdapter'; Get-CimInstance Win32_NetworkAdapter -ComputerName $Hostname | Format-List *;"
    "Write-Host 'Win32_NetworkAdapterConfiguration'; Get-CimInstance Win32_NetworkAdapter -ComputerName $Hostname | Format-List *;"
})                                                                        #
                                                                          #
$ViewSoftwareButton          = New-Object System.Windows.Forms.Button     #
#$ViewSoftwareButton.Size     = New-Object System.Drawing.Size(110, 23)  # not sure if they were sized manually for a reason but we're trying autosizing
$ViewSoftwareButton.AutoSize = $true                                      #
$ViewSoftwareButton.Location = New-Object System.Drawing.Point(145, 245)  #
$ViewSoftwareButton.Text     = "View Installed Software"                  #
$ViewSoftwareButton.FlatStyle= $global:FlatStyle                          #
                                                                          #
# GUI options based on configuration                                      #
                                                                          #
$ViewSoftwareButton.Add_Click({                                           #
  #$IS = Get-InstalledSoftware $Hostname                                   #
  [System.Windows.Forms.MessageBox]::Show("Looks like you've found a new feature! We haven't implemented this one quiiiiite yet, but someday we'll have this button launch a window where you can see a list of all the software on a computer, and remotely uninstall most of it.", "Pardon our dust!")                   #
})                                                                        #

$Form.Controls.AddRange(@(
  $ProcessorLabel,$ProcessorInfoBox,
  $HardwareLabel,$HardwareInfoBox,
  $SoftwareLabel,$SoftwareInfoBox,
  $DiskLabel,$DiskInfoBox,
  $NetworkLabel,$NetworkInfoBox
  #$UserLabel,$UserInfoBox
  $MoreInfoButton #,
#  $ViewSoftwareButton
))
$Form.ShowDialog()