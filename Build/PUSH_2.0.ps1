<#Chapter 0: Information#>
<#
.SYNOPSIS
  Tool to remotely install software, manage, and do other fun things with on ETS computers.
.DESCRIPTION
  PUSH is like any other Windows tool, it's better if you use the GUI.
.PARAMETER d
  Optional, runs push in debug mode (extra stuff output to console and to the outputbox if using GUI)
.PARAMETER light
  Run push in light mode. You monster ;)
.PARAMETER logfile
  Optional, the name of the log file.
.INPUTS
  nothing
.OUTPUTS
  A log file, optionally (enabled by default). You can disable the log file if you're running push in silent mode.
.NOTES
  Version:          2.0.9
  Authors:          Kyle Ketchell, Matt Smith
  Version Creation: August 2, 2022
  Orginal Creation: May 29, 2022
.EXAMPLE
  push_2.0
.EXAMPLE
  push_2.0 -silent ComputerName SoftwareTitle
  Silently install "SoftwareTitle" on "ComputerName"
  The title of the software must match EXACTLY the name of the software's folder in the Push\Software directory
.EXAMPLE
  push_2.0 -Configure "\\path\to\your\custom\configuration\file.xml"
  Push reads information from a Configuration file. So, like, you can make it behave however the Configuration.xml file says.
  Note - don't forget to include things that are in the configuration.xml file already.
#>
#[CmdletBinding()]
param(                                                                    # Parameters Ref: Microsoft, Parameters
  [Parameter(ParameterSetName = "GUI")][Switch]$d=$false,                 # d (debug)
  [Parameter(ParameterSetName = "GUI")][Switch]$b=$false,                 # b (beta version). Not one you normally pass, but used internally to determine version info.
  <#-light will be deprecated in favor of using -ColorScheme and -Design Scheme parameters in 2.8, gone in 2.1#>
  [Parameter(ParameterSetName = "GUI")][Switch]$light=$false,             # light (light mode)
  [Parameter()][Alias("l")][Switch]$dolog=$false,                         # choose whether the session will output to a log
  [Parameter()][String]$logfile="",                                       # specify name of log file
  [Parameter()][Alias("h")][Switch]$help=$false,                          # print a help message and quit
  [Parameter()][Alias("dir")][String]$Execution_Directory="\\software.engr.colostate.edu\software\ENS\Push_2.0", # Where is Push executing from?
  [Parameter()][String]$Fallback_Directory="\\software.engr.colostate.edu\software\ENS\Push_2.0",
  [Parameter()][String]$Configure="\\software.engr.colostate.edu\software\ENS\Push_2.0\Configuration.xml", # You can specify no parameters!
  [Parameter()][String]$ColorScheme="Dark",                               #
  [Parameter()][String]$DesignScheme="Original",                          #
  [Parameter()][Alias("q")][Switch]$Quiet,                                # this is low key my favorite parameter to pass :)
  [Parameter()][PSCredential]$Credential                                  #
)                                                                         #

###########################################################################
# DOCUMENTATION: $debug option for compiler                               #
# When you run the "compile" application in PUSH\Build it creates 2       #
# executables, one in the PUSH folder that doesn't run with -d and one in #
# the PUSH\Build folder that does run with the -d flag. The first line    #
# #$d = $true should ALWAYS be commented out,                             #
# this is the way the compile script sets the flag. Please don't touch it.#
###########################################################################
#$d=$true                                                                 #
#$b=$true                                                                 #
if ($d) { Write-Host 'debug mode'}                                        # if we're in debug mode, say it
if ($b) { Write-Host 'Beta version'}                                      # if this is a beta version, say it
###########################################################################

if ($Credential) { $script:Credential = $Credential }                     # If we provided a credential object, store it in the $script:Credential object. This will be helpful later.

###########################################################################
# Documentation: Initialize Push                                          #
# Push needs a few helper modules and such to get imported, this imports  #
# those and gets everything set up to run.                                #
###########################################################################
# Step 1: Make our lives way easier and just move over to the right place #
Set-Location $Execution_Directory                                         # Move us to the location specified by the $Exectuion_Directory variable
if ($d) { Write-Host "Current Location: $((Get-Location).Path)" }         # if we're debugging, say where we are rn
                                                                          #
#Test if location is a valid push directory                               #
if (-Not (Test-Path .\Build\Push_Config_Manager.psm1)) {                  #
  Write-Host "Missing Push Config manager. Is $((Get-Location).Path) a valid push directory? Falling back to a known location"
  Set-Location $Fallback_Directory                                        #
  if (-Not (Test-Path .\Build\Push_Config_Manager.psm1)) {                #
    Write-Host "Still unable to find Push Config Manager. Is $((Get-Location).Path) a valid directory? Exiting."
    Write-Host "For help, run Get-Help Push_2.0.ps1"                      #
    exit                                                                  #
  }                                                                       #
}                                                                         #
###########################################################################

###########################################################################
# Documentation: Help message                                             #
# When running silently, one may wish to see what command line parameters #
# are available. This outputs some help info, and then quits.             #
###########################################################################
if ($help) {                                                              #
  Get-Help ".\Build\Push_2.0.ps1"                                         #
  exit                                                                    # print the help message, and exit
}                                                                         #
###########################################################################

# Step 2: Import the necessary sub modules, and use them as needed        #
#if (Get-Module Push_Config_Manager) { Remove-Module Push_Config_Manager } # Remove the Configuration Manager (if imported)
#Import-Module .\Build\Push_Config_Manager.psm1                            # Import the Configuration manager
#$Config = Get-PUSH_Configuration $Configure -ColorScheme $ColorScheme -Design $DesignScheme -Application "PUSH" # Get the configuration settings
#if ($light) { $Config = Get-PUSH_Configuration $Configure -ColorScheme "Light" -Design "Classic" -Application "PUSH" } # Get the light configuration settings

# Step 2: Import the necessary sub modules, and use them as needed
###########################################################################
# Documentation: Initalize Push                                           #
# There are a bunch of useful sub modules which need to be imported and   #
# used to get everything going. We (remove them if they're imported) then #
# import them, then start using them to do PUSH things.                   #
###########################################################################
if (Get-Module Push_Config_Manager) { Remove-Module Push_Config_Manager } #
if (Get-Module Install_Software) { Remove-Module Install_Software }       #
if (Get-Module Push_Logger) { Remove-Module Push_Logger }                 #
if (Get-Module PUSH_GUI_Manager) { Remove-Module PUSH_GUI_Manager }       #
if (Get-Module PUSHapps_ToolStrip) { Remove-Module PUSHapps_ToolStrip }   #
                                                                          #
Import-Module .\Build\Push_Config_Manager.psm1                            #
Import-Module .\Build\Install_Software.psm1                               #
Import-Module .\Build\Push_Logger.psm1                                    #
Import-Module .\Build\PUSH_GUI_Manager.psm1                               #
Import-Module .\Build\PUSHapps_ToolStrip.psm1                             #
                                                                          # v Get the configuration v
$Config = Get-PUSH_Configuration $Configure -ColorScheme $ColorScheme -Design $DesignScheme -Application "PUSH"
                                                                          # ^ Get the configuration ^
########################################################################  #
# Documentation: Create a log file                                     #  #
# Just for the sake of making sure we know what happened, PUSH creates #  #
# log files of stuff that happened. Things get added to this file via  #  #
# the log function. The file is created here.                          #  #
########################################################################  #
if ($dolog){                                                           #  # only if the $dolog -l parameter is included
  if ($logfile -ne "") { $lfilename = $logfile }                       #  # if we specified a name for logfile, set it, otherwise:
  else { if ($d) { $lfilename = $Config.Package.Logs+"\"+(Get-Date -Format "MM.dd.yyyy-HH.mm")+"-d.log"}  # the special debug name
        else { $lfilename = $Config.Package.Logs+"\"+(Get-Date -Format "MM.dd.yyyy-HH.mm")+".log" } } # the name of the logfile
  Write-Host "Trying logfile $lfilename"                               #  # Write that we're trying to use that logfile
                                                                       #  #
  try {                                                                #  # try this:
    If (-Not (test-path $lfilename)) { New-Item $lfilename }           #  # Make a new file if there isn't one
  }   catch {                                                          #  # if it failed:
    $lfilename = "C:\Users\$ENV:USERNAME\Push_log_$(Get-Date -Format "MM.dd.yyyy-HH.mm")" # try another name
  }                                                                    #  # 
                                                                       #  #
  $lfilename = Convert-Path ($lfilename)                               #  # get the file as an object
                                                                       #  #
  Enable-PushLogging                                                   #  #
  Set-PushLogfileLocation $lfilename                                   #  #
}                                                                      #  #
########################################################################  #
                                                                          #
if ($Quiet) {                                                             #
  Disable-PushConsoleOutput                                               #
}                                                                         #
# Step 3: TODO: Trust engr_dom on this computer                           #
###########################################################################

<#Chapter 2: Setup the GUI form #>
###########################################################################
# Documentation: Add Types                                                #
# Add the things you need in order to make gui happen.                    #
###########################################################################
Add-Type -AssemblyName System.Windows.Forms                               # Add the Forms type
Add-Type -AssemblyName System.Drawing                                     # add the drawing type
[System.Windows.Forms.Application]::EnableVisualStyles()                  # Enable us to use colors
###########################################################################

###########################################################################
# Documentation: Global Variables                                         #
# These are variables that everything should be able to access            #
###########################################################################
if (-Not $d) { $ErrorActionPreference = 'SilentlyContinue' }              # Set the erroractionpreference (don't throw a bunch of error messages that a user won't understand)
                                                                          #
# The $OutputBox is created here to avoid errors reading through the      #
# softwareinstall function.                                               #
$OutputBox            = New-Object System.Windows.Forms.TextBox           # Create the output box textbox object
###########################################################################

###########################################################################
# Documentation: Get Username and Password                                #
# The username and password need to have access to the network share      #
# where PUSH is located AND must have admin privelages on the machine.    #
###########################################################################
function GetCreds {                                                       #
  param([PSCredential]$Credential)                                        #
                                                                          #
  log "GetCreds: Called with: $($Credential.Username)" 0                  #
                                                                          #
  # Base case                                                             #
  if (-Not $Credential) {                                                 #
    log "GetCreds: No credentials provided. Requesting credentials." 0    #
    $CredMessage = "Please provide valid credentials."                    # Message to display
    $user = "$env:UserDomain\$env:USERNAME"                               # Default username
    $Credential = Get-Credential -Message $CredMessage -UserName $user    # Ref Get-Credential
    if (-Not $Credential) {                                               #
      log "GetCreds: User probably clicked Cancel." 0                     #
      return -1                                                           #
    }                                                                     #
    log "GetCreds: Proceeding with PSCredential Object with username: $($Credential.Username)" 0
  }                                                                       #
                                                                          #
  log "GetCreds: Testing PSCredential Object..." 0                        #
                                                                          #
  # Test the credentials                                                  #
  try {                                                                   #
    Start-Process Powershell -ArgumentList "Start-Sleep",0 -Credential $Credential -WorkingDirectory 'C:\Windows\System32' -NoNewWindow
    Powershell -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope CurrentUser"
  } catch {                                                               #
    if ($_ -like "*password*") {                                          # the system will complain, bad password
      log "GetCred: Bad password provided." 0                             #
      Start-Process Powershell -ArgumentList "Add-Type -AssemblyName System.Windows.Forms;",
      "[System.Windows.Forms.MessageBox]::Show('Bad Password! Try again!','Uh-oh.')" -WindowStyle Hidden  # show a popup about it
      $Credential = GetCreds                                              #
    } elseif ($_ -like "*is not null or empty*") {                        # If we didn't provide any password
      log "GetCred: No password provided." 0                              #
      $OKC = Start-Process Powershell -ArgumentList "Add-Type -AssemblyName System.Windows.Forms;",
      "[System.Windows.Forms.MessageBox]::Show('Please enter a password. Click Cancel to cancel the operation.','Whoopsie.',OKCancel)" -WindowStyle Hidden # show a popup about it
      if ($OKC -eq "Cancel") { return -1 }                                #
      $Credential = GetCreds                                              #
    }                                                                     #
  }                                                                       #
                                                                          #
  log "GetCreds: Returning Credential Object: $($Credential.Username)"    #
  return $Credential                                                      #
}                                                                         #
###########################################################################

<#Chapter 2: Set up the GUI form#>
###########################################################################
# Documentation: Main Form  [Now in Dark Mode]                            #
# GUI stuff comes in 2 basic sections, object definitions/design, and     #
# action definitions. An object (like a form or a button) is defined by   #
# creating a new object, and then setting each attribute in that object.  #
# For example: Create a button, then define the text, size, location,     #
# color, etc. Then, you'll define the action that happens if you click    #
# that button with the Add_[event] method. you can Add_Click for a button #
# or Add_SelectedIndexChanged for a list, etc. In that Add_[event]        #
# definition is where actual code/script exists.                          #
###########################################################################
$GUIForm          = New-Object system.Windows.Forms.Form                  # Create a new form object
$GUIForm.TopMost  = $true                                                 # make it be the top thing
$GUIForm.Add_MouseEnter({$GUIForm.TopMost = $false})                      # but then not as soon as we hover over it
log "Generated Form object" 0 # Debugging checkpoint                      #
                                                                          #
#######################################################################   #
# Documentation: Declare all of the stuff in the form                 #   #
# I created each of the form objects here. The properties for everything  #
# (like where it is, and how big and whatnot) are all set later on.   #   #
# Pro tip: this is kind of like a table of contents for the rest of   #   #
# the script, you'll find each of these things set up in roughly the  #   #
# same order as they're defined here.                                 #   #
#######################################################################   #
$SelectLabel          = New-Object System.Windows.Forms.Label         #   # Create a new label for the dropdown
$SelectLabDropdown    = New-Object System.Windows.Forms.ComboBox      #   # Create a dropdown menu
                                                                      #   #
$SelectAll            = New-Object System.Windows.Forms.Button        #   # Replaces Act on all machines feature
$SelectNone           = New-Object System.Windows.Forms.Button        #   # Create a select no machines button
$MachineList          = New-Object System.Windows.Forms.ListBox       #   # Create a ListBox for the machines
$InstallOnSelMachines = New-Object System.Windows.Forms.Button        #   # Add a "selected machines" button
                                                                      #   #
$ManualSectionHeader  = New-Object System.Windows.Forms.Label         #   # Create a label for the Manual section
$OrLabel              = New-Object System.Windows.Forms.Label         #   # Create a label for the manual box
$ManualNameTextBox    = New-Object System.Windows.Forms.TextBox       #   # Create an input box for a machine name
$ApplyToManualEntry   = New-Object System.Windows.Forms.Button        #   # Create a button to act on machine name
$EnterPS              = New-Object System.Windows.Forms.Button        #   # Create a button to enter a pssession
$ScanComputer         = New-Object System.Windows.Forms.Button        #   # Create a button to scan a computer
# Depreciated $BETATESTINSTALLER    = New-Object System.Windows.Forms.Button        #   # Create a button to beta test the new installer functionality
                                                                      #   #
$RunExecutablesList   = New-Object System.Windows.Forms.ListBox       #   # Create a ListBox to hold software
$SoftwareFilterTextBox= New-Object System.Windows.Forms.TextBox       #   # Create a textbox to filter list of software
$SoftwareFilterLabel  = New-Object System.Windows.Forms.Label         #   # Label for the software filter text box
$FixesCheckBox        = New-Object System.Windows.Forms.CheckBox      #   # Create a fixes checkbox
$SoftwareCheckBox     = New-Object System.Windows.Forms.CheckBox      #   # Create a software checkbox
$UpdatesCheckBox      = New-Object System.Windows.Forms.CheckBox      #   # Create a Updates checkbox
# The OutputBox is created with the Global Variables, to avoid errors #   # $OutputBox            = New-Object System.Windows.Forms.TextBox       #   # Create the Output text box
$DoneLabel            = New-Object System.Windows.Forms.Label         #   # Create a done label
                                                                      #   #
$GUIForm.Controls.AddRange(@(                                         #   # Add all of those ^ to the form
  $SelectLabel, $SelectLabDropdown,                                   #   # Add the select lab stuff
  $SelectAll, $SelectNone, $MachineList, $InstallOnSelMachines        #   # Add the select machines stuff
  $ManualSectionHeader, $OrLabel, $ManualNameTextBox,                 #   # Add the manual entry stuff
  $ApplyToManualEntry, $EnterPS, $ScanComputer,                       #   # Add the manual entry buttons
  $RunExecutablesList, <#$CSSPCheckBox,#> $FixesCheckBox,             #   # Add the exectuables list
  $SoftwareCheckBox, $SoftwareFilterTextBox, $UpdatesCheckBox,        #   #
  $SoftwareFilterLabel, $OutputBox, $DoneLabel   #   # Add the executables stuff
))                                                                    #   #
log "Added controls to form" 0 # Debugging checkpoint                 #   #
#######################################################################   #
log "Generated GUI form" 0 # Debugging checkpoint                         #
###########################################################################

#Invoke-GenerateGUI -Config $Config -Application "PUSH"
                                                                          #
#######################################################################   #
# Documentation: Select Lab: label                                    #   #
# Just some text so that you know what the select lab dropdown does.  #   #
#######################################################################   #
$SelectLabel.text      = "Select Lab:"                                #   # The label says "Select lab:"
#$SelectLabel.Font      = New-Object System.Drawing.Font($global:FontSettings) # and have that font
log "Configured Select Label" 0 # Debugging checkpoint                 #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: the Select Lab dropdown menu                         #   # ref ComboBox, Microsoft Docs
# How do we get a bunch of  file names into the dropdown menu?        #   #
# Get-ChildItem allows us to get the names of all visible items (or   #   #
# add -Force to also get hidden items) in a folder. Then we iterate   #   #
# through each filename and cut out just the name (and remove the     #   #
# .txt at the end) and put that text into the dropdown menu.          #   #
#######################################################################   #
$SelectLabDropdown.text      = "Select..."                            #   # make it say "Select..." by default
$SelectLabDropdown.Items.Add("All Machines") *> $null                 #   # Add an "All" option to the combo box
                                                                      #   #
###################################################################   #   #
# Documentation: get the name of the group from the .txt file     #   #   #
# The groups folder contains severl .txt files with the names of  #   #   #
# every computer in a group. The name of the group is the title of#   #   #
# the .txt file, but the .txt extention is ugly. Cut that out,    #   #   #
# then put the name into the selectlabdropdown menu.              #   #   #
###################################################################   #   #
Get-ChildItem -Path $Config.Package.Groups |                      #   #   #
  ForEach-Object {                                                #   #   # Iterate through $GroupsFolderLocation
    $GroupName = $_.Name.Substring(0,$_.Name.length-4)            #   #   # Get the filename, cut off .txt
    $SelectLabDropdown.Items.Add($GroupName) *> $null             #   #   # Add the name to the SelectLabDropdown
  }                                                               #   #   #
###################################################################   #   #
                                                                      #   #
###################################################################   #   #
# Documentation: do something if we select an item from the list  #   #   #
# If the user changes the selected index (chooses a group) then   #   #   #
# set the selected lab, and populate the list of machines.        #   #   #
###################################################################   #   #
$SelectLabDropdown.Add_SelectedIndexChanged({                     #   #   # Add behvior for selectedindexchanged
  $SelectedLab = $SelectLabDropdown.SelectedItem                  #   #   # set the variable $SelectedLab
  log "Selected Lab: $SelectedLab" 1                              #   #  ### debug, which lab we selected
  $MachineList.Items.Clear()                                      #   #   # Clear out the $MachineList
  if ($SelectedLab -ne "All Machines") {                          #   #   # If we didn't select "All machines"
    $GroupFileName = "$($Config.Package.Groups)\$SelectedLab.txt"  #   # Set the name of the group file
    log "Reading File: $GroupFileName" 1                          #   #  ### debug which file we're reading
    Get-Content -Path $GroupFileName | ForEach-Object {           #   #   # iterate through each line in the file
      $MachineList.Items.Add($_) *> $null                         #   #   # Add that line to the list of machines
    }                                                             #   #   #
  } else {                                                        #   #   # If we DID select "All Machines"
    Get-ChildItem -Path $Config.Package.Groups | ForEach-Object {   # Iterate through every file in $Groups
      $groupfilename = "$($Config.Package.Groups)\$_"          #   #   # set the name of the group file
      log "Reading File: $GroupFileName" 1                        #   #  ### log which file we're reading
      Get-Content -Path $GroupFileName | ForEach-Object {         #   #   # read the file line by line
        $MachineList.Items.Add($_) *> $null                       #   #   # add the line into the list of machines
      }                                                           #   #   #
    }                                                             #   #   #
  }                                                               #   #   #
})                                                                #   #   #
###################################################################   #   #
log "Generated SelectLabDropdown menu" 1 # Debug Checkpoint           #   #
#######################################################################   # end of select lab dropdown
                                                                          #
#######################################################################   #
# Documentation: Select All button                                    #   #
# if no or some objects are selected from the machine list, then you  #   #
# can toggle to select all items from the list. If all items are      #   #
# selected, you can select no items from the list.                    #   #
#######################################################################   # Set up the Select button:
$SelectAll.Text   = "Select All"                                      #   # set the text (it might change later)
                                                                      #   #           
$SelectAll.Add_Click({                                                #   # add click behavior
  For ($itemslenghth = 0; $itemslenghth -lt $MachineList.Items.Count; $itemslenghth++){
    $MachineList.SetSelected($itemslenghth,$true)                     #   # select every item
  }                                                                   #   #
})                                                                    #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Select None button                                   #   #
# if no or some objects are selected from the machine list, then you  #   #
# can toggle to select all items from the list. If all items are      #   #
# selected, you can select no items from the list.                    #   #
#######################################################################   # Set up the Select button:
$SelectNone.Text      = "Select None"                                 #   # set the text (it might change later)
                                                                      #   #           
$SelectNone.Add_Click({                                               #   # add click behavior
  For ($itemslenghth = 0; $itemslenghth -lt $MachineList.Items.Count; $itemslenghth++){
    $MachineList.SetSelected($itemslenghth,$false)                    #   # set every item to not be selected
  }                                                                   #   #
})                                                                    #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Machine List / List of Machines / Computers          #   #
# This is a MultiExtended list box (it's a list box) in which you can #   #
# select multiple items. All of the computers in a group are added to #   #
# this box when you select a group from the lab dropdown menu         #   #
# (cf. $SelectLabDropdown.Add_SelectedIndexChanged() )                #   #
# Notice we don't define the stuff in the machine list here - this    #   #
# list will get filled on the fly when the user selects a lab.        #   #
#######################################################################   # For the machine list:
log "Generated machinelist object" 0 # Debugging checkpoint           #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Apply to Selected Machines button                    #   #
# When you click this button, it will act on any machines selected    #   #
#######################################################################   # Define the button to have...
$InstallOnSelMachines.text      = "Install Software"                  #   # that text
                                                                      #   #
$InstallOnSelMachines.Add_Click({                                     #   # Define a click behavior:
  $script:Credential = GetCreds -Credential $script:Credential
  if ($script:Credential -eq -1) {
    return
  }
  $ListSelectedMachines = $MachineList.SelectedItems                  #   # get all selected machines
  log "Working on these machines:" 1                                  #  ### Write which machines we're doing
  $ListSelectedMachines | ForEach-Object { log $_ 1 }                 #  ### write out the name of each machine
  $ListSelectedSoftware = $RunExecutablesList.SelectedItems           #   # get the selected software
  #if ($UseCredSSP) { CSSPSoftwareInstall $global:SelectedMachines $global:SelectedSoftware } else { softwareinstall $global:SelectedMachines $global:SelectedSoftware }   #   # call the softwareinstall function
  Invoke-Install -Machines $ListSelectedMachines -Installers $ListSelectedSoftware -Credential $script:Credential -Config $Config
})                                                                    #   #
log "Generated ActOnSelMachines button" 0 # Debugging Checkpoint      #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Manual Name Section                                  #   #
# You can also use PUSH on a single computer by typing in the name    #   #
# manually, this is the section (and header that points that out).    #   #
#######################################################################   #
$ManualSectionHeader.Text     = "Work on a single computer: "         #   #
log "Generated ManualSectionHeader" 0 # debugging checkpoint          #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Or Label                                             #   #
# If a user wants to manually enter a computer name, do it here       #   #
# (and tell them that this is the place to do that).                  #   #
#######################################################################   # the OR label:
$OrLabel.text      = "Enter Name:"                                    #   # says that
log "Generated OR Label" 0 # Debugging checkpoint                     #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: the manual entry box                                 #   #
# Instead of selecting a lab or computers, you can also manually enter#   #
# a computer name to work on.                                         #   #
#######################################################################   # For the manual entry box:
$ManualNameTextBox.text       = ""                                    #   # make it say nothing by default

$ManualNameTextBox.Add_KeyDown({                                      #   # If we press a key
  If ($PSItem.KeyCode -eq "Enter"){                                   #   # If it was the enter key
    $BETATESTINSTALLER.PerformClick()                                 #   # click the "ApplytoManualEntry" button
  }                                                                   #   #
})                                                                    #   #
if ($d) { $ManualNameTextBox.Text = "Alfred-VM" }                     #   #
log "Generated Manual Name Text Box" 0 # Debugging checkpoint         #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Apply to Manual entered machine button               #   #
# When you click this button it will install any selected software on #   #
# the computer name you typed into the $manualnametextbox             #   #
#######################################################################   # Apply to Manual Entry button:
$ApplyToManualEntry.text      = "Install Software"                    #   # Make it say that
                                                                      #   #
$ApplyToManualEntry.Add_Click({                                       #   # add a click behavior for the button
  # Invoke-Installer
  $script:Credential = GetCreds -Credential $script:Credential
  if ($script:Credential -eq -1) {
    return
  }
  $BETAEnteredComputer = $ManualNameTextBox.text                      #   # the machines are whatever we entered
  log "Working on this machine: $BETAEnteredComputer" 2               #   # Write we're working on a computer
  $BETASelectedSoftware = $RunExecutablesList.SelectedItems           #   # Select the software we chose
  #if ($UseCredSSP) { CSSPSoftwareInstall $global:SelectedMachines $global:SelectedSoftware } else { softwareinstall $global:SelectedMachines $global:SelectedSoftware }   #   # call the softwareinstall function
  Invoke-Install -Machines $BETAEnteredComputer -Installers $BETASelectedSoftware -Config $Config <#-UseCredSSP $global:UseCredSSP#> -Credential $script:Credential
  # Old installer
  # $global:SelectedMachines = $ManualNameTextBox.text                  #   # the machines are whatever we entered
  # log "Working on this machine: $global:SelectedMachines" 2           #  ### Write we're working on a computer
  # $global:SelectedSoftware = $RunExecutablesList.SelectedItems        #   # Select the software we chose
  # if ($UseCredSSP) { CSSPSoftwareInstall $global:SelectedMachines $global:SelectedSoftware } else { softwareinstall $global:SelectedMachines $global:SelectedSoftware }   #   # call the softwareinstall function
})                                                                    #   #
log "Generated ActOnManual button" 0 # Debugging checkpoint           #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Enter PSSession                                      #   #
# You can enter powershell sessions with remote computers. This button#   #
# automates that for you.                                             #   #
#######################################################################   # EnterPS Button:
$EnterPS.Text            = "Enter-PSSession"                          #   # says that
                                                                      #   #
$EnterPS.Add_Click({                                                  #   #
  $name = $ManualNameTextBox.text                                     #   #
  log "Starting PSSession with '$name'" 1                             #   #
  Start-Process powershell -ArgumentList "-NoExit","Enter-PSSession",$name #
  log "Control returned to PUSH" 0                                    #   #
})                                                                    #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Scan Computer                                        #   #
# Launch the Host Scanner tool and scan the selected computer.        #   #
#######################################################################   # set up the map printer button
$ScanComputer.Text       = "Scan Computer"                            #   # with that text
                                                                      #   #
$ScanComputer.Add_Click({                                             #   # add click behavior:
  log "Launching Scan_Host with $($ManualNameTextBox.Text)" 1         #   #
  # start Scan_Host using typed computer name                         #   #
  $OutputBox.AppendText("Scanning"); Start-Sleep -Milliseconds 300; $OutputBox.AppendText("."); Start-Sleep -Milliseconds 300; $OutputBox.AppendText(".")
  Start-Sleep -Milliseconds 300; $OutputBox.AppendText(".`r`n") # kind of rudimentary but its also awesome looking so deal with it :cool-glasses:
  Start-Process Powershell -ArgumentList "powershell .\Build\Scan_Host.exe -Hostname $($ManualNameTextBox.Text) -dir $Execution_Directory -configure $Configure -ColorScheme $ColorScheme -DesignScheme $DesignScheme" -NoNewWindow
  #powershell -File .\Build\Scan_Host.ps1 -Hostname $ManualNameTextBox.Text -dir "$Execution_Directory" -configure $Configure -ColorScheme $ColorScheme -DesignScheme $DesignScheme
#  & .\Build\Scan_Host.ps1 -Hostname $ManualNameTextBox.Text -dir "$Execution_Directory" -configure $Configure -ColorScheme $ColorScheme -DesignScheme $DesignScheme
})                                                                    #   #
log "Generated Scan_Host button" 0 # Debugging Checkpoint             #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Select Software to Install list                      #   #
# This is a list of the available folders in the P:\Software folder   #   #
#######################################################################   # For the RunExecutables list:
log "Generated Executables list box" 0 # Debugging checkpoint         #   #
                                                                      #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: loadSoftware                                         #   #
# Search through the software folders, and if any match these special #   #
# names that need to be installed with CredSSP Authentication, add    #   #
# those separately.                                                   #   #
#######################################################################   #
function loadSoftware {                                               #   # Create the loadSoftware function
  param([bool]$Fixes=$false,[bool]$Software=$true,[bool]$Updates=$false)  # call with paramters to generate list
  $RunExecutablesList.Items.Clear()                                   #   # clear out the Executables list
  if ($d) {                                                           #   # if we're running in debug mode:
    Get-ChildItem -Path $Config.Package.Software -Force -filter "*$($SoftwareFilterTextBox.Text)*" | ForEach-Object { # get hidden items in the software folder
      if ($_.FullName -like "*fix*" -and $Fixes) {                    #   #
        $RunExecutablesList.Items.Add($_.Name) *> $null               #   # add that software to the list
      }                                                               #   #
      elseif ($_.FullName -like "*update*" -and $Updates) {
        $RunExecutablesList.Items.Add($_.Name) *> $null
      }
      elseif ($_.FullName -notlike "*fix*" -and $_.FullName -notlike "*update*" -and $Software) {
        $RunExecutablesList.Items.Add($_.Name)  *> $null              #   # add that software to the list
      }                                                               #   #
    }                                                                 #   #
  } else {                                                            #   # If not debug mode:
    Get-ChildItem -Path $Config.Package.Software -filter "*$($SoftwareFilterTextBox.Text)*" | ForEach-Object { # Iterate through $Software
      if ($_.FullName -like "*fix*" -and $Fixes) {                    #   #
        $RunExecutablesList.Items.Add($_.Name) *> $null               #   # add that software to the list
      }                                                               #   #
      elseif ($_.FullName -like "*update*" -and $Updates) {
        $RunExecutablesList.Items.Add($_.Name) *> $null
      }
      elseif ($_.FullName -notlike "*fix*" -and $_.FullName -notlike "*update*" -and $Software) {
        $RunExecutablesList.Items.Add($_.Name)  *> $null              #   # add that software to the list
      }                                                               #   #
    }                                                                 #   #
  }                                                                   #   #
  log "Filled Executables List" 0 # Debugging checkpoint              #  ### log it
}                                                                     #   #
loadSoftware                                                          #   # call the function to load the list the first time around
#######################################################################   #
                                                                          # 
#######################################################################   #
# Documentation: Software Filter Label                                #   #
# Label that displays on top of Software Filter Text Box              #   #
#######################################################################   #
#use the software filter label
$SoftwareFilterLabel.Text = "Search:"
$SoftwareFilterLabel.visible   = $true
<#
$SFLX = ($SoftwareFilterTextBox.Location.X) #+ 2)                       #   # the x location of the done label, relative to the outputbox
$SFLY = ($SoftwareFilterTextBox.Location.Y)# + $SoftwareFilterTextBox.Height - 12)              #   # the y location of the done label, relative to the outputbox
$SoftwareFilterLabel.Location  = New-Object System.Drawing.Point($SFLX, $SFLY)     #   # is there (this is a relative location to the $outputbox, so it appears at the bottom)
$SoftwareFilterLabel.Forecolor = $Config.ColorScheme.Foreground      #   # that color
$SoftwareFilterLabel.visible   = $true                               #   # and invisible! (we're not done yet)
$SoftwareFilterLabel.BringToFront() 
#>
#######################################################################   #
# Documentation: Software Filter Text Box                             #   #
# Input in the textbox will be used to filter the list of software    #   #
#                                                                     #   #
#######################################################################   #
$SoftwareFilterTextBox.Add_TextChanged({
  loadSoftware -Fixes $FixesCheckBox.Checked -Software $SoftwareCheckBox.Checked -Updates $UpdatesCheckBox.Checked
})
                                                                      #   #
#######################################################################   #
# Documentation: Fixes Check Box                                      #   #
# Not all software installs actually end up in a New installed Software   #
# some just change a registry entry or something. These are Fixes. To #   #
# keep things organized, we can filter by Software or Fixes.          #   #
#######################################################################   #
$FixesCheckBox.Text     = "Fixes"                                     #   #
$FixesCheckBox.Checked  = $false                                      #   #
log "Generated Fix Button" 0 # Debugging checkpoint                   #  ### log we made the checkbox
                                                                      #   #
#if ($UseCredSSP) {$CSSPCheckBox.Checked = $true}                      #   # if we passed that parameter, check the box 
$FixesCheckBox.Add_CheckStateChanged({                                #   # if we change the state of the checkbox:
  loadSoftware -Fixes $FixesCheckBox.Checked -Software $SoftwareCheckBox.Checked -Updates $UpdatesCheckBox.Checked # call the loadsoftware function to scan the list of executables
})                                                                    #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Software Check Box                                   #   #
# Some software installs really are software installs. To keep things #   #
# organized, we can check this box to show software.                  #   #
#######################################################################   #
$SoftwareCheckBox.Text       = "Software"                             #   #
$SoftwareCheckBox.Checked    = $true                                  #   #
log "Generated Software Checkbox" 0 # Debugging checkpoint            #  ### log we made the checkbox
                                                                      #   #
#if ($UseCredSSP) {$CSSPCheckBox.Checked = $true}                      #   # if we passed that parameter, check the box 
$SoftwareCheckBox.Add_CheckStateChanged({                             #   # if we change the state of the checkbox:
  loadSoftware -Fixes $FixesCheckBox.Checked -Software $SoftwareCheckBox.Checked -Updates $UpdatesCheckBox.Checked # call the loadsoftware function to scan the list of executables
})                                                                    #   #
#######################################################################   #

#######################################################################   #
# Documentation: Updates CheckBox                                     #   #
# If you want to get "Update" software available in PUSH, check this  #   #
#######################################################################   #
$UpdatesCheckBox.Text = "Updates"
$UpdatesCheckBox.Checked = $false
log "Generated Updates Checkbox"

$UpdatesCheckBox.Add_CheckStateChanged({
  loadSoftware -Fixes $FixesCheckBox.Checked -Software $SoftwareCheckBox.Checked -Updates $UpdatesCheckBox.Checked
})
                                                                          #
#######################################################################   #
# Documentation: Output Box                                           #   #
# This is the box that displays text in the GUI form.                 #   #
#######################################################################   # Set up the Output box to be:
log "Running in Debug Mode" 1                                         #  ### log that
log "Generated OutputBox" 0 # Debugging checkpoint                    #   #
#######################################################################   #
                                                                          #                                                                       
#######################################################################   #
# Documentation: Finished installing label                            #   #
# When the processes installing that software finish installing, some #   #
# text appears saying that the software finished installing.          #   #
#######################################################################   # the Done label:
$DoneLabel.Text      = "Not done yet"                                 #   # Says that
$DoneLabel.Forecolor = $Config.ColorScheme.Success                    #   # that color
#$DLX = ($OutputBox.Location.X + 2)
#$DLY = ($OutputBox.Location.Y + $OutputBox.Height - 40)
#$DoneLabel.Location  = New-Object System.Drawing.Point($DLX,$DLY)
$DoneLabel.visible   = $false                                         #   # and invisible! (we're not done yet)
$DoneLabel.BringToFront()                                             #   # bring it to the front
log "Generated Done Label" 0 # Debugging checkpoint                   #   #
#######################################################################   #

$ToolStrip = Get-PUSHToolStrip -Config $Config -Application "PUSH" -ConfigurationFile $Configure -dir $Execution_Directory

$TSFExitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$TSFExitItem.Text = "&Exit"
$TSFExitItem.Add_MouseEnter({ $this.ForeColor = $Config.ColorScheme.ToolStripHover })
$TSFExitItem.Add_MouseLeave({ $this.ForeColor = $Config.ColorScheme.Foreground })
$TSFExitItem.BackColor = $Config.ColorScheme.ToolStripBackground
$TSFExitItem.ForeColor = $Config.ColorScheme.Foreground
$TSFExitItem.Add_Click({ $GUIForm.Close() })
$ToolStrip.Items.Item($ToolSTrip.GetItemAt(5, 2)).DropDownItems.Add($TSFExitItem)

$GUIForm.Controls.Add($ToolStrip)                                     #   # add the tool strip to the form

$GUIContextMenu = New-Object System.Windows.Forms.ContextMenu

$GCMSetDarkMode = New-Object System.Windows.Forms.MenuItem
$GCMSetDarkMode.Text = "Change to Dark Mode"
$GCMSetDarkMode.Add_Click({
  log "Changing to Dark Mode" 0
  $GUIContextMenu.MenuItems.Remove($GCMSetDarkMode)
  $GUIContextMenu.MenuItems.Add($GCMSetLightMode)
  $Config = Set-PUSH_Configuration $Config -ColorScheme "Dark" -Design "Original"
  Invoke-GenerateGUI -Config $Config -Application "PUSH" -StyleOnly
  RefreshPushToolStrip -ToolStrip $ToolStrip -Config $Config -Application "PUSH" 
})
$GCMSetLightMode = New-Object System.Windows.Forms.MenuItem
$GCMSetLightMode.Text = "Change to Light Mode"
$GCMSetLightMode.Add_Click({
  log "Changing to Light mode" 0
  $GUIContextMenu.MenuItems.Remove($GCMSetLightMode)
  $GUIContextMenu.MenuItems.Add($GCMSetDarkMode)
  $Config = Set-PUSH_Configuration $Config -ColorScheme "Light" -Design "Modern"
  Invoke-GenerateGUI -Config $Config -Application "PUSH" -StyleOnly
  RefreshPushToolStrip -ToolStrip $ToolStrip -Config $Config -Application "PUSH" 
})

$GUIContextMenu.MenuItems.AddRange(@($GCMSetLightMode))

$GUIForm.ContextMenu = $GUIContextMenu

#######################################################################   #
# Documentation: Dump some information about this instance to a log   #   #
# It can be helpful to have information about this current instance in#   #
# a log file, so this gets a bunch of information about this computer #   #
# and throws it to a log file.                                        #   #
#######################################################################   #
log "===========================================" 0                   #   #
log "Version: $($Config.About.Version)"           0                   #   # log the version
log "Beta: $b"                                    0                   #   # log if we're running in beta mode
log "DEBUG: $d"                                   0                   #   # log if we're running in debug mode
log "Running on: $env:COMPUTERNAME"               0                   #   # log the computer we're running on
log "by user: $env:USERNAME"                      0                   #   # log the username
log "with authentication as $($Creds.Username)"   0                   #   # log the user we're using to connect to other computers
log "-------------------------------------------" 0                   #   #
log "ColorScheme: $($Config.ColorScheme.Name)"    0                   #   #
log "Design: $($Config.Design.Name)"              0                   #   #
log "Package: $($Config.Package.Location)"        0                   #   #
log "===========================================" 0                   #   #
#######################################################################   #
                                                                          #
#######################################################################   #
# Documentation: Show the form                                        #   #
# I would think that it's pretty obvious that this is important, bc   #   #
# its a singular line of code all on its own. But apparently not      #   #
# everyone thinks that this line is important. So I put in this box to#   #
# say "This next line is very important don't remove it". What this   #   #
# does is it actually shows the form containing aaaaaalll of the      #   #
# stuff we just generated up there ^ in a nice GUI box. If this line  #   #
# is gone, the program won't work. So plz don't delete this line.     #   #
#######################################################################   #
log "Starting UI..." 0                                                #   # Log beginning of UI
Invoke-GenerateGUI -Config $Config -Application "PUSH"                #   #
$GUIForm.ShowDialog()                                                 #   # Show the form
#######################################################################   #
                                                                          #
########################################################################### end of the GUI form

###########################################################################
# Exit behavior                                                           #
###########################################################################
#Remove-PSDrive (Get-PSDrive -Name P)                                      # Push no longer maps a drive on the current session
###########################################################################

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
