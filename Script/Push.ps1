<#
.SYNOPSIS
  Tool to remotely install software, manage, and do other fun things with on domain-joined computers.
.DESCRIPTION
  PUSH is like any other Windows tool, it's better if you use the GUI.
.INPUTS
  nothing
.OUTPUTS
  A log file, optionally (enabled by default). You can disable the log file if you're running push in silent mode.
.NOTES
  Version:          2.1
  Authors:          Kyle Ketchell, Matt Smith
  Version Creation: November 7, 2022
  Orginal Creation: May 29, 2022
.EXAMPLE
  push_2.0
#>
[cmdletBinding()]
param(
  [Parameter()][Alias("h")][Switch]$help=$false,
  [Parameter()][String]$Configure="\\software.engr.colostate.edu\software\ENS\Push_2.0\Configuration.xml",
  [Parameter()][String]$ColorScheme="Dark",
  [Parameter()][String]$DesignScheme="Original",
  [Parameter()][PSCredential]$Credential
)

if (-Not (Test-Path $PSScriptRoot\Push_Config_Manager.psm1)) {
  Write-Host "Missing Push Config manager. Is $((Get-Location).Path) a valid push directory?"
  exit
}

if ($help) {
  Get-Help "$PSScriptRoot\Push_2.0.ps1"
  exit
}

if (Get-Module Push_Config_Manager) { Remove-Module Push_Config_Manager }
if (Get-Module Install_Software) { Remove-Module Install_Software }
if (Get-Module PUSH_GUI_Manager) { Remove-Module PUSH_GUI_Manager }
if (Get-Module PUSHapps_ToolStrip) { Remove-Module PUSHapps_ToolStrip }
if (Get-Module CredentialManager) {Remove-Module CredentialManager}

Import-Module $PSScriptRoot\Push_Config_Manager.psm1
Import-Module $PSScriptRoot\Install_Software.psm1
Import-Module $PSScriptRoot\PUSH_GUI_Manager.psm1
Import-Module $PSScriptRoot\PUSHapps_ToolStrip.psm1
Import-Module $PSScriptRoot\CredentialManager.psm1

if ($Credential) { Set-StoredPSCredential $Credential }

$Config = Get-PUSH_Configuration $Configure -ColorScheme $ColorScheme -Design $DesignScheme -Application "PUSH"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
#[System.Windows.Forms.Application]::EnableVisualStyles() # maybe this is a color thing?

$OutputBox            = New-Object System.Windows.Forms.TextBox

<#
function GetCreds {
  param([PSCredential]$Credential)
  if (-Not $Credential) {
    $CredMessage = "Please provide valid credentials."
    $user = "$env:UserDomain\$env:USERNAME"
    $Credential = Get-Credential -Message $CredMessage -UserName $user
    if (-Not $Credential) {
      return -1
    }
  }

  try {
    Start-Process Powershell -ArgumentList "Start-Sleep",0 -Credential $Credential -WorkingDirectory 'C:\Windows\System32' -NoNewWindow
    Powershell -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope CurrentUser"
  } catch {
    if ($_ -like "*password*") {
      Write-Verbose "GetCred: Bad password provided."
      Start-Process Powershell -ArgumentList "Add-Type -AssemblyName System.Windows.Forms;",
      "[System.Windows.Forms.MessageBox]::Show('Bad Password! Try again!','Uh-oh.')" -WindowStyle Hidden
      $Credential = GetCreds
    } elseif ($_ -like "*is not null or empty*") {
      Write-Verbose "GetCred: No password provided."
      $OKC = Start-Process Powershell -ArgumentList "Add-Type -AssemblyName System.Windows.Forms;",
      "[System.Windows.Forms.MessageBox]::Show('Please enter a password. Click Cancel to cancel the operation.','Whoopsie.',OKCancel)" -WindowStyle Hidden
      if ($OKC -eq "Cancel") { return -1 }
      $Credential = GetCreds
    }
  }

  log "GetCreds: Returning Credential Object: $($Credential.Username)"
  return $Credential
}#>

$GUIForm          = New-Object system.Windows.Forms.Form
#$GUIForm.UseSystemColors = $true #https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.professionalcolortable.usesystemcolors?view=windowsdesktop-7.0

$SelectLabel          = New-Object System.Windows.Forms.Label
$SelectLabDropdown    = New-Object System.Windows.Forms.ComboBox

$SelectAll            = New-Object System.Windows.Forms.Button
$SelectNone           = New-Object System.Windows.Forms.Button
$MachineList          = New-Object System.Windows.Forms.ListBox
$InstallOnSelMachines = New-Object System.Windows.Forms.Button

$ManualSectionHeader  = New-Object System.Windows.Forms.Label
$OrLabel              = New-Object System.Windows.Forms.Label
$ManualNameTextBox    = New-Object System.Windows.Forms.TextBox
$ApplyToManualEntry   = New-Object System.Windows.Forms.Button
$EnterPS              = New-Object System.Windows.Forms.Button
$ScanComputer         = New-Object System.Windows.Forms.Button

$RunExecutablesList   = New-Object System.Windows.Forms.ListBox
$SoftwareFilterTextBox= New-Object System.Windows.Forms.TextBox
$SoftwareFilterLabel  = New-Object System.Windows.Forms.Label
$FixesCheckBox        = New-Object System.Windows.Forms.CheckBox
$SoftwareCheckBox     = New-Object System.Windows.Forms.CheckBox
$UpdatesCheckBox      = New-Object System.Windows.Forms.CheckBox
$DoneLabel            = New-Object System.Windows.Forms.label

$GUIForm.Controls.AddRange(@(
  $SelectLabel, $SelectLabDropdown,
  $SelectAll, $SelectNone, $MachineList, $InstallOnSelMachines,
  $ManualSectionHeader, $OrLabel, $ManualNameTextBox,
  $ApplyToManualEntry, $EnterPS, $ScanComputer,
  $RunExecutablesList, $FixesCheckBox,
  $SoftwareCheckBox, $SoftwareFilterTextBox, $UpdatesCheckBox,
  $SoftwareFilterLabel, $OutputBox, $DoneLabel
))

#Invoke-GenerateGUI -Config $Config -Application "PUSH"

$SelectLabel.text      = "Select Lab:"                                #   # The label says "Select lab:"
#$SelectLabel.Font      = New-Object System.Drawing.Font($global:FontSettings) # and have that font

$SelectLabDropdown.text      = "Select..."
$SelectLabDropdown.Items.Add("All Machines") *> $null

Get-ChildItem -Path $Config.Package.Groups |
  ForEach-Object {
    $GroupName = $_.Name.Substring(0,$_.Name.length-4)
    $SelectLabDropdown.Items.Add($GroupName) *> $null
  }

$SelectLabDropdown.Add_SelectedIndexChanged({
  $SelectedLab = $SelectLabDropdown.SelectedItem
  $MachineList.Items.Clear()
  if ($SelectedLab -ne "All Machines") {
    $GroupFileName = "$($Config.Package.Groups)\$SelectedLab.txt"
    Get-Content -Path $GroupFileName | ForEach-Object {
      $MachineList.Items.Add($_) *> $null
    }
  } else {
    Get-ChildItem -Path $Config.Package.Groups | ForEach-Object {
      $groupfilename = "$($Config.Package.Groups)\$_"
      Get-Content -Path $GroupFileName | ForEach-Object {
        $MachineList.Items.Add($_) *> $null
      }
    }
  }
})


$SelectAll.Text   = "Select All"
$SelectAll.Add_Click({
  For ($itemslenghth = 0; $itemslenghth -lt $MachineList.Items.Count; $itemslenghth++){
    $MachineList.SetSelected($itemslenghth,$true)
  }
})


$SelectNone.Text      = "Select None"
$SelectNone.Add_Click({
  For ($itemslenghth = 0; $itemslenghth -lt $MachineList.Items.Count; $itemslenghth++){
    $MachineList.SetSelected($itemslenghth,$false)
  }
})


$InstallOnSelMachines.text      = "Install Software"
$InstallOnSelMachines.Add_Click({
  $CredentialObject = Get-StoredPSCredential
  if ($CredentialObject -eq -1) {
    return
  }
  $ListSelectedMachines = $MachineList.SelectedItems
  $ListSelectedSoftware = $RunExecutablesList.SelectedItems
  Write-Verbose "Installing $ListSelectedSoftware on $ListSelectedMachines"
  Invoke-Install -Machines $ListSelectedMachines -Installers $ListSelectedSoftware -Credential $script:Credential -Config $Config
})


$ManualSectionHeader.Text     = "Work on a single computer: "


$OrLabel.text      = "Enter Name:"


$ManualNameTextBox.text = ""

$ManualNameTextBox.Add_KeyDown({
  If ($PSItem.KeyCode -eq "Enter"){
    $ScanComputer.PerformClick()
  }
})


$ApplyToManualEntry.text      = "Install Software"

$ApplyToManualEntry.Add_Click({
  $CredentialObject = Get-StoredPSCredential
  if ($CredentialObject -eq -1) {
    return
  }
  $SelectedComputer = $ManualNameTextBox.text
  $SelectedSoftware = $RunExecutablesList.SelectedItems
  Write-Verbose "Installing $SelectedSoftware on $SelectedComputer"
  Invoke-Install -Machines $BETAEnteredComputer -Installers $BETASelectedSoftware -Config $Config -Credential $CredentialObject
})


$EnterPS.Text            = "Enter-PSSession"

$EnterPS.Add_Click({
  $name = $ManualNameTextBox.text
  Start-Process powershell -ArgumentList "-NoExit","Enter-PSSession",$name
})


$ScanComputer.Text       = "Scan Computer" 

$ScanComputer.Add_Click({
  $OutputBox.AppendText("Scanning"); Start-Sleep -Milliseconds 300; $OutputBox.AppendText("."); Start-Sleep -Milliseconds 300; $OutputBox.AppendText(".")
  Start-Sleep -Milliseconds 300; $OutputBox.AppendText(".`r`n") # kind of rudimentary but its also awesome looking so deal with it
  Start-Process Powershell -ArgumentList "powershell .\Build\Scan_Host.exe -Hostname $($ManualNameTextBox.Text) -dir $Execution_Directory -configure $Configure -ColorScheme $ColorScheme -DesignScheme $DesignScheme" -NoNewWindow
})

function loadSoftware {
  param([bool]$ShowHidden)
  $RunExecutablesList.Items.Clear()
  if ($ShowHidden) {
    Get-ChildItem -Path $Config.Package.Software -filter "*$($SoftwareFilterTextBox.Text)*" -Force | ForEach-Object {
      $RunExecutablesList.Items.Add($_.Name) *> $null
    }
  } else {
    Get-ChildItem -Path $Config.Package.Software -filter "*$($SoftwareFilterTextBox.Text)*" | ForEach-Object {
      $RunExecutablesList.Items.Add($_.Name) *> $null
    }
  }
}
loadSoftware

$SoftwareFilterLabel.Text = "Search:"
$SoftwareFilterLabel.visible   = $true

$SoftwareFilterTextBox.Add_TextChanged({
  loadSoftware -ShowHidden $FixesCheckBox.Checked
})

$FixesCheckBox.Text     = "Hidden:"
$FixesCheckBox.Checked  = $false
$FixesCheckBox.Add_CheckStateChanged({
  loadSoftware -Fixes $FixesCheckBox.Checked -Software $SoftwareCheckBox.Checked -Updates $UpdatesCheckBox.Checked
})

$SoftwareCheckBox.Text       = "Software"
$SoftwareCheckBox.Checked    = $true
$SoftwareCheckBox.Add_CheckStateChanged({
  loadSoftware -Fixes $FixesCheckBox.Checked -Software $SoftwareCheckBox.Checked -Updates $UpdatesCheckBox.Checked
})

$UpdatesCheckBox.Text = "Updates"
$UpdatesCheckBox.Checked = $false

$UpdatesCheckBox.Add_CheckStateChanged({
  loadSoftware -Fixes $FixesCheckBox.Checked -Software $SoftwareCheckBox.Checked -Updates $UpdatesCheckBox.Checked
})

$DoneLabel.Text      = "Not done yet"
$DoneLabel.Forecolor = $Config.ColorScheme.Success
$DoneLabel.visible   = $false
$DoneLabel.BringToFront()

$ToolStrip = Get-PUSHToolStrip -Config $Config -Application "PUSH" -ConfigurationFile $Configure -dir $Execution_Directory

$TSFExitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$TSFExitItem.Text = "&Exit"
$TSFExitItem.Add_MouseEnter({ $this.ForeColor = $Config.ColorScheme.ToolStripHover })
$TSFExitItem.Add_MouseLeave({ $this.ForeColor = $Config.ColorScheme.Foreground })
$TSFExitItem.BackColor = $Config.ColorScheme.ToolStripBackground
$TSFExitItem.ForeColor = $Config.ColorScheme.Foreground
$TSFExitItem.Add_Click({ $GUIForm.Close() })
$ToolStrip.Items.Item($ToolSTrip.GetItemAt(5, 2)).DropDownItems.Add($TSFExitItem)

$GUIForm.Controls.Add($ToolStrip)

<#$GUIContextMenu = New-Object System.Windows.Forms.ContextMenu

$GCMSetDarkMode = New-Object System.Windows.Forms.MenuItem
$GCMSetDarkMode.Text = "Change to Dark Mode"
$GCMSetDarkMode.Add_Click({
  $GUIContextMenu.MenuItems.Remove($GCMSetDarkMode)
  $GUIContextMenu.MenuItems.Add($GCMSetLightMode)
  $Config = Set-PUSH_Configuration $Config -ColorScheme "Dark" -Design "Original"
  Invoke-GenerateGUI -Config $Config -Application "PUSH" -StyleOnly
  RefreshPushToolStrip -ToolStrip $ToolStrip -Config $Config -Application "PUSH" 
})
$GCMSetLightMode = New-Object System.Windows.Forms.MenuItem
$GCMSetLightMode.Text = "Change to Light Mode"
$GCMSetLightMode.Add_Click({
  $GUIContextMenu.MenuItems.Remove($GCMSetLightMode)
  $GUIContextMenu.MenuItems.Add($GCMSetDarkMode)
  $Config = Set-PUSH_Configuration $Config -ColorScheme "Light" -Design "Modern"
  Invoke-GenerateGUI -Config $Config -Application "PUSH" -StyleOnly
  RefreshPushToolStrip -ToolStrip $ToolStrip -Config $Config -Application "PUSH" 
})

$GUIContextMenu.MenuItems.AddRange(@($GCMSetLightMode))

$GUIForm.ContextMenuStrip = $GUIContextMenu#>

Invoke-GenerateGUI -Config $Config -Application "PUSH"
$GUIForm.ShowDialog()

#########################################################################################################################################################################################################################
# Ref    (I know I didn't use MLA format but I used Code format citations so...)                                                                                                                                        #
# Reference      | Explanation                                    | URL                                                                                                                                                 #
# POSHGUI        | Create a Powershell GUI (like, drag'n'drop)    | https://poshgui.com/                                                                                                                                #
# Hide popups    | Hide the "are you sure" security popup         | https://www.atmosera.com/blog/handling-open-file-security-warning/
#                                                                                                                                                                                                                       #
# Microsoft Docs | Multi-selection list box                       | https://docs.microsoft.com/en-us/powershell/scripting/samples/multiple-selection-list-boxes?view=powershell-7.2                                     #
# Microsoft Docs | Get-Credential                                 | https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-credential?view=powershell-7.2                                 #
# Microsoft Docs | Colors                                         | https://docs.microsoft.com/en-us/dotnet/api/system.drawing.color?view=net-6.0                                                                       #
# Microsoft Docs | List of Colors                                 | https://docs.microsoft.com/en-us/dotnet/api/system.windows.media.brushes?view=windowsdesktop-6.0                                                    #
# Microsoft Docs | ComboBox                                       | https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox?view=windowsdesktop-6.0                                                   #
# Microsoft Docs | Parameters                                     | https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameter_sets?view=powershell-7                           #
# Microsoft Docs | Parameter Sets                                 | https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/how-to-declare-parameter-sets?view=powershell-7.2                            #
# StackOverflow  | if network path exists                         | https://stackoverflow.com/questions/46565176/powershell-checking-if-network-drive-exists-if-not-map-it-then-double-check                            #
# theITBros      | For each item in a folder                      | https://theitbros.com/powershell-script-for-loop-through-files-and-folders/                                                                         #
# itechguides    | For each line in a file                        | https://www.itechguides.com/foreach-in-file-powershell/                                                                                             #
#########################################################################################################################################################################################################################
