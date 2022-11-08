<#
.SYNOPSIS
  Script to remotely view, manage, and end user sessions on a remote Windows 10 computer. For which you are an administrator (duh).
.DESCRIPTION
  This script will scan a host and find any logged on users. You can then select user sessions to shadow or end. Alternativly, scan one or more hosts for a particular user by searching through the resutls of an AD querey.
.PARAMETER s, silent 
  REQUIRED: Run in silent mode. You must provide either a computer (hostname) to scan or a username to scan for.
.PARAMETER c, computer
  Required: Provide a computer name to scan for
.PARAMETER u, user
  Required: Provide a username to scan for, PUSH will then prompt you to enter an AD query to find a list of hosts to scan.
.PARAMETER l, light
  Optional, Run UI in light mode
.NOTES
  Version:       1.5 [Real Resurrection]
  Author:        Kyle Ketchell
  Creation Date: 6/21/22
.EXAMPLE
  .\SessionManager.ps1
.EXAMPLE
  .\SessionManager.ps1 -s -c MyOfficeComputer
.EXAMPLE
  .\SessionManager.ps1 -s -u frontdeskuser
.EXAMPLE
  .\SessionManager.ps1 -l
#>
param(                                                                                # Parameters:
  [String]$Configure="..\Configuration.xml",                                          # The PUSH configuration file we're reading from
  [String]$ColorScheme="Dark",                                                        # the Color Scheme we're using
  [String]$DesignScheme="Original",                                                   # the Design Scheme we're using
  [Alias("dir")][String]$Execution_Directory="\\software.engr.colostate.edu\software\ENS\Push_2.0\Build", # the place we're executing from
#  [Switch]$light = $false,                                                            # light mode
  [Switch]$d = $false,                                                                # debug mode (not sure if this gets used?)
  [Alias("C")][String]$Computer                                                       # specify -computer or -c
)                                                                                     #
####################################################################################### Parameters/Flags/Args

#######################################################################################
# PUSH Session Manager                                                                #
# View and Edit sessions on a remote computer                                         #
#                                                                                     #
# Author: Kyle Ketchell (Software Guru)                                               #
#         kkatfish@cs.colostate.edu                                                   #
#         6/21/2022                                                                   #
#######################################################################################

#######################################################################################
# Documentation: Import necessary prerequisites                                       #
# Get the Forms and drawing types, as well as the configuration preferences.          #
#######################################################################################
Set-Location $Execution_Directory                                                     # Move us to the $Execution Directory, so we're in the right place to import this stuff from
                                                                                      #
Add-Type -AssemblyName System.Windows.Forms   #Initialize the powershell gui          # ref itbros.com
Add-Type -AssemblyName System.Drawing         #I'm pretty sure this is also important # ref itbros.com

if (Get-Module Push_Config_Manager) { Remove-Module Push_Config_Manager }             # Remove the Push_Config_Manager module
if (Get-Module Session_Manager) { Remove-Module Session_Manager}                      # Remove the Session_Manager module

Import-Module .\Build\Push_Config_Manager.psm1                                              # Import the Push_Config_Manager module
Import-Module .\Build\Session_Manager.psm1                                                  # Import the Session_Manager module

$Config = Get-PUSH_Configuration $Configure -ColorScheme $ColorScheme -Design $DesignScheme -Application "Session_Manager" # Get our configuraiton
#if ($light) {                                                                         # if we want light mode
#  $Config = Get-PUSH_Configuration $Configure -ColorScheme "Light" -Design $DesignScheme -Application "Session_Manager" # get the light configuration
#}                                                                                     #
                                                                                      #
########################################################################              #
# Documentation - Create a new **special** drive just for the location #              #
# of PUSH 2.0. if Push drive exists, move on, otherwise map it.        #              #
########################################################################              #Ref. StackOverflow
<# not necessary
If (Test-Path -Path $Config.Package.Build) {                           #              # If the drive is mapped:
  if ($d) { Write-Host "Not Mapping P drive again."}                   #              # say it exists (if we're in debug mode)
}                                                                      #              # move on
else {                                                                 #              # otherwise:
  if ($d) { Write-Host "Mapping P to $($Config.Package.Location)" }    #              # Write that we're mapping the P:\ drive
  $PDrive = $Config.Package.Location                                   #              # decide where it will map to
  New-PSDrive -Name P -Root $PDrive -Credential $script:Creds -PsProvider "Filesystem" # map it
}                                                                      #              #
#>
########################################################################              #
#######################################################################################

#######################################################################################
# Documentation: These variables ought to be global, else bad things will happen.     #
#######################################################################################
$global:BackgroundColor = $Config.ColorScheme.Background                              # ref Colors
$global:ForegroundColor = $Config.ColorScheme.Foreground                              # 
$global:Font = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)
$global:Sessions = ""                                                                 #
#######################################################################################

#######################################################################################
# Documentation: Main form                                                            #
# This is the main form, where all the magic happens. This is defined in a function   #
# (Main) which is then called at the end of the script, just to maintain readability. #
#######################################################################################
function Main {                                                                       # def; Main function
  $SessionManagerForm               = New-Object System.Windows.Forms.Form            # Create a form object
  $SessionManagerForm.Text          = "$($Config.About.Name) $($Config.About.Version) - $($Config.About.Nickname)" # with that title
  $SessionManagerForm.Size          = New-Object System.Drawing.Size(600,400)         # that size
  $SessionManagerForm.StartPosition = 'CenterScreen'                                  # that start oh lordie i can't do this for every line. This should make sense.
  $SessionManagerForm.Topmost       = $true                                           # Set it to be topmost- 
  $SessionManagerForm.Add_MouseEnter({$SessionManagerForm.TopMost = $false})          # but as soon as we wave the mouse over it, it isn't topmost anymore.
  $SessionManagerForm.BackColor     = $Config.ColorScheme.Background                         # 
  $SessionManagerForm.ForeColor     = $Config.ColorScheme.Foreground                         #
  $SessionManagerForm.Icon          = $Config.Design.Icon                             #
  $SessionManagerForm.Font          = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                    #
                                                                                      #
  $FindLabel           = New-Object System.Windows.Forms.Label                        # Find label
  $FindLabel.Text      = "Find:"                                                      #
  $FindLabel.Location  = New-Object System.Drawing.Point(10, 10)                      #
  $FindLabel.Size      = New-Object System.Drawing.Size(40, 23)                       # 
  $FindLabel.ForeColor = $Config.ColorScheme.Foreground                                      #
  $FindLabel.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                                 #
  $SessionManagerForm.Controls.Add($FindLabel)                                        #
                                                                                      #
  $FindDropdown = New-Object System.Windows.Forms.ComboBox                            # Find dropdown 
  $FindDropdown.Location = New-Object System.Drawing.Point(50, 10)                    #
  $FindDropdown.Size = New-Object System.Drawing.Size(300, 23)                        #
  $FindDropdown.BackColor = $Config.ColorScheme.Background                                   #
  $FindDropdown.ForeColor = $Config.ColorScheme.Foreground                                   #
  $FindDropdown.FlatStyle = $Config.Design.FlatStyle                                         #
  $FindDropdown.Font = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                                   #
  $FindDropdown.Items.AddRange(@(                                                     # Add the items to the dropdown:
    "All users on [some computer]",                                                   #
    "[Some user] on [some computer]",                                                 #
    "[Some User] on a PUSH group of computers",                                       #
    "All Users on a PUSH group of Computers",                                         #
    "[Some User] on an AD group of computers",                                        #
    "All users on an AD group of computers"))                                         #
#  if ($Computer) { $FindDropdown.SelectedIndex = 0 }                                  #
  $SessionManagerForm.Controls.Add($FindDropdown)                                     #
                                                                                      #
  $HostnameLabel           = New-Object System.Windows.Forms.Label                    # Hostname label
  $HostnameLabel.Text      = "Computer: "                                             # 
  $HostnameLabel.Location  = New-Object System.Drawing.Point(10, 35)                  #
  $HostnameLabel.Size      = New-Object System.Drawing.Size(75, 23)                   #
  $HostnameLabel.ForeColor = $Config.ColorScheme.Foreground                                  #
  $HostnameLabel.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                             #
  $SessionManagerForm.Controls.Add($HostnameLabel)                                    #
                                                                                      #
  $HostnameBox           = New-Object System.Windows.Forms.TextBox                    # Hostname TextBox
  $HostnameBox.Location  = New-Object System.Drawing.Point(85, 35)                    #
  $HostnameBox.Size      = New-Object System.Drawing.Size(200, 23)                    #
  $HostnameBox.ForeColor = $Config.ColorScheme.Background                                    #
  $HostnameBox.BackColor = $Config.ColorScheme.Foreground                                    #
  $HostnameBox.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                               #
  $HostnameBox.Enabled   = $false                                                     #
  $SessionManagerForm.Controls.Add($HostnameBox)                                      #
                                                                                      #
  $GroupLabel           = New-Object System.Windows.Forms.Label                       # Group label
  $GroupLabel.Text      = "Group: "                                                   #
  $GroupLabel.Location  = New-Object System.Drawing.Point(290, 35)                    #
  $GroupLabel.Size      = New-Object System.Drawing.Size(90, 23)                      #
  $GroupLabel.ForeColor = $Config.ColorScheme.Foreground                                     #
  $GroupLabel.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                                #
  $SessionManagerForm.Controls.Add($GroupLabel)                                       #
                                                                                      #
  $GroupBox           = New-Object System.Windows.Forms.ComboBox                      # Group Box
  $GroupBox.Location  = New-Object System.Drawing.Point(385, 35)                      #
  $GroupBox.Size      = New-Object System.Drawing.Size(200, 23)                       #
  $GroupBox.ForeColor = $Config.ColorScheme.Background                                       #
  $GroupBox.BackColor = $Config.ColorScheme.Foreground                                       #
  $GroupBox.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                                  #
  $GroupBox.FlatStyle = $Config.Design.FlatStyle                                         #
  $GroupBox.Enabled   = $false                                                        #
  $SessionManagerForm.Controls.Add($GroupBox)                                         #
                                                                                      #
  $UsernameLabel           = New-Object System.Windows.Forms.Label                    # Username label
  $UsernameLabel.Text      = "Username: "                                             #
  $UsernameLabel.Location  = New-Object System.Drawing.Point(10, 60)                  #
  $UsernameLabel.Size      = New-Object System.Drawing.Size(75, 23)                   #
  $UsernameLabel.ForeColor = $Config.ColorScheme.Foreground                                  #
  $UsernameLabel.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                             #
  $SessionManagerForm.Controls.Add($UsernameLabel)                                    #
                                                                                      #
  $UsernameBox           = New-Object System.Windows.Forms.TextBox                    # Username textbox
  $UsernameBox.Location  = New-Object System.Drawing.Point(85, 60)                    #
  $UsernameBox.Size      = New-Object System.Drawing.Size(200, 23)                    # 
  $UsernameBox.ForeColor = $Config.ColorScheme.Background                                    #
  $UsernameBox.BackColor = $Config.ColorScheme.Foreground                                    #
  $UsernameBox.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                               #
  $UsernameBox.Enabled   = $false                                                     #
  $SessionManagerForm.Controls.Add($UsernameBox)                                      #
                                                                                      # Here's some fun comments!
  $FindDropdown.Add_SelectedIndexChanged({                                            # Add a behavior: If we change the dropdown item in the Find menu:
    switch ($FindDropdown.SelectedItem) {                                             # switch/case (Which dropdown menu item did we select?:
      "All users on [some computer]" {                                                # All users on some computer:
        $HostnameBox.BackColor = $Config.ColorScheme.Background                              # 
        $HostnameBox.ForeColor = $Config.ColorScheme.Foreground                              # 
        $HostnameBox.Enabled   = $true                                                #   Enable the hostname box
        $UsernameBox.BackColor = $Config.ColorScheme.Foreground                              #
        $UsernameBox.ForeColor = $Config.ColorScheme.Background                              #
        $UsernameBox.Enabled   = $false                                               #   Disable the Username box
        $GroupBox.BackColor    = $Config.ColorScheme.Foreground                              #
        $GroupBox.ForeColor    = $Config.ColorScheme.Background                              #
        $GroupBox.Enabled      = $false                                               #   Disable the group box
      }                                                                               #
      "[Some user] on [some computer]" {                                              # Some user on Some computer:
        $HostnameBox.BackColor = $Config.ColorScheme.Background                              #
        $HostnameBox.ForeColor = $Config.ColorScheme.Foreground                              #
        $HostnameBox.Enabled   = $true                                                #   Enable the hostname box
        $UsernameBox.BackColor = $Config.ColorScheme.Background                              #
        $UsernameBox.ForeColor = $Config.ColorScheme.Foreground                              #
        $UsernameBox.Enabled   = $true                                                #   Enable the username box
        $GroupBox.BackColor    = $Config.ColorScheme.Foreground                              #
        $GroupBox.ForeColor    = $Config.ColorScheme.Background                              #
        $GroupBox.Enabled      = $false                                               #   Disable the group box
      }                                                                               #
      "[Some User] on a PUSH group of computers" {                                    # Some user on a PUSH group:
        $HostnameBox.BackColor = $Config.ColorScheme.Foreground                              #
        $HostnameBox.ForeColor = $Config.ColorScheme.Background                              #
        $HostnameBox.Enabled   = $false                                               #   Disable the hostname box
        $UsernameBox.BackColor = $Config.ColorScheme.Background                              #
        $UsernameBox.ForeColor = $Config.ColorScheme.Foreground                              #
        $UsernameBox.Enabled   = $true                                                #   Enable the Username box
        $GroupBox.BackColor    = $Config.ColorScheme.Background                              #
        $GroupBox.ForeColor    = $Config.ColorScheme.Foreground                              #
        $GroupBox.Enabled      = $true                                                #   Enable the group box
        $GroupLabel.Text       = "PUSH Group:"                                        #   Set the group label to be "PUSH Group:"
        $GroupBox.Items.Clear()                                                       #   Clear the groups dropdown
        $GroupBox.Text = ""                                                           #
        $Groups = Get-ChildItem $Config.Package.Groups | Select-Object -Property Name #   get the groups from the Push folder
        $Groups | ForEach-Object {                                                    #   iterate through the group files:
          $GroupBox.Items.Add($_.Name.SubString(0, $_.Name.length-4))                 #   add the name (minus the .txt at the end of the filename) to the groups dropdown
        }                                                                             #
      }                                                                               #
      "All Users on a PUSH group of Computers" {                                      # All users on a PUSH group:
        $HostnameBox.BackColor = $Config.ColorScheme.Foreground                              #
        $HostnameBox.ForeColor = $Config.ColorScheme.Background                              #
        $HostnameBox.Enabled   = $false                                               #    Disable the hostname box
        $UsernameBox.BackColor = $Config.ColorScheme.Foreground                              #
        $UsernameBox.ForeColor = $Config.ColorScheme.Background                              #
        $UsernameBox.Enabled   = $false                                               #    Disable the username box
        $GroupBox.BackColor    = $Config.ColorScheme.Background                              #
        $GroupBox.ForeColor    = $Config.ColorScheme.Foreground                              #
        $GroupBox.Enabled      = $true                                                #    Enable the group box
        $GroupLabel.Text = "PUSH Group:"                                              #    Set the group label to "PUSH Group:"
        $GroupBox.Items.Clear()                                                       #    clear the groups dropdown
        $GroupBox.Text = ""                                                           #
        $Groups = Get-ChildItem $Config.Package.Groups | Select-Object -Property Name #    get the groups from Push's groups folder
        $Groups | ForEach-Object {                                                    #    iterate through the group files:
          $GroupBox.Items.Add($_.Name.SubString(0, $_.Name.length-4))                 #    Add the name of the group (minus the .txt at the end of the filename) to the groups dropdown
        }                                                                             #
      }                                                                               #
      "[Some User] on an AD group of computers"{                                      # Some user on an AD Group:
        $HostnameBox.BackColor = $Config.ColorScheme.Foreground                              #
        $HostnameBox.ForeColor = $Config.ColorScheme.Background                              #
        $HostnameBox.Enabled   = $false                                               #    Disable the hostname box
        $UsernameBox.BackColor = $Config.ColorScheme.Background                              #
        $UsernameBox.ForeColor = $Config.ColorScheme.Foreground                              #
        $UsernameBox.Enabled   = $true                                                #    Enable the username box
        $GroupBox.BackColor    = $Config.ColorScheme.Background                              #
        $GroupBox.ForeColor    = $Config.ColorScheme.Foreground                              #
        $GroupBox.Enabled      = $true                                                #    Enable the groups dropdown
        $GroupLabel.Text = "AD Group:"                                                #    Set the group label to "AD Group:"
        $GroupBox.Items.Clear()                                                       #    Clear the groups dropdown
        $GroupBox.Text = ""
        $Config.Preferences.AD_Preferences.OUs.OU | ForEach-Object {                  #    Get the OUs from the Config object (draws from the configuration file)
          $GroupBox.Items.Add($_.Name)                                                #    add the name of the OU to the group box
        }                                                                             #
      }                                                                               #
      "All users on an AD group of computers" {                                       # All users on an AD Group:
        $HostnameBox.BackColor = $Config.ColorScheme.Foreground                              #
        $HostnameBox.ForeColor = $Config.ColorScheme.Background                              #
        $HostnameBox.Enabled   = $false                                               #    Disable the hostname box
        $UsernameBox.BackColor = $Config.ColorScheme.Foreground                              #
        $UsernameBox.ForeColor = $Config.ColorScheme.Background                              #
        $UsernameBox.Enabled   = $false                                               #    Disable the username box
        $GroupBox.BackColor    = $Config.ColorScheme.Background                              #
        $GroupBox.ForeColor    = $Config.ColorScheme.Foreground                              #
        $GroupBox.Enabled      = $true                                                #    Enable the Group box
        $GroupLabel.Text = "AD Group:"                                                #    Set the group label to "AD Group:"
        $GroupBox.Items.Clear()                                                       #    Clear out the group box dropdown
        $GroupBox.Text = ""                                                           #
        $Config.Preferences.AD_Preferences.OUs.OU | ForEach-Object {                  #    Get the OUs from the Config object
          $GroupBox.Items.Add($_.Name)                                                #    add the name of each OU to the group box
        }                                                                             #
      }                                                                               #
    }                                                                                 #
  })                                                                                  #
                                                                                      #
  $FindButton           = New-Object System.Windows.Forms.Button                      # Find button
  $FindButton.Text      = "Find!"                                                     #
  $FindButton.Location  = New-Object System.Drawing.Point(290, 60)                    #
  $FindButton.Size      = New-Object System.Drawing.Size(50, 23)                      #
  $FindButton.ForeColor = $Config.ColorScheme.Foreground                                     #
  $FindButton.BackColor = $Config.ColorScheme.Background                                     #
  $FindButton.FlatStyle = $Config.Design.FlatStyle                                           #
  $FindButton.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                                #
  $SessionManagerForm.Controls.Add($FindButton)                                       #
                                                                                      #
  $ResultList           = New-Object System.Windows.Forms.ListBox                     # Result list box
  $ResultList.Location  = New-Object System.Drawing.Point(10, 100)                    #
  $ResultList.Size      = New-Object System.Drawing.Size(300, 200)                    #
  $ResultList.ForeColor = $Config.ColorScheme.Foreground                                     #
  $ResultList.BackColor = $Config.ColorScheme.Background                                     #
  $ResultList.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                                #
  $SessionManagerForm.Controls.Add($ResultList)                                       #
                                                                                      #
  $CountLabel           = New-Object System.Windows.Forms.Label                       #
  $CountLabel.Text      = "Count: "                                                   #
  $CountLabel.Size      = New-Object System.Drawing.Size(200, 25)                     #
  $CountLabel.Location  = New-Object System.Drawing.Point(10, 305)                    #
  $CountLabel.ForeColor = $Config.ColorScheme.Foreground                                     #
  $ResultList.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                                #
  $SessionManagerForm.Controls.Add($CountLabel)                                       #
                                                                                      # ooh, more fun comments!
  $FindButton.Add_Click({                                                             #
    $ResultList.Items.Clear()                                                         #
    switch ($FindDropdown.SelectedItem) {                                             # 
      "All users on [some computer]" {                                                # 
        $Hostname = $HostnameBox.Text                                                 # 
        $global:Sessions = Get-Quser -ServerName $Hostname                            # 
        $global:Sessions | ForEach-Object {                                           # 
          if (-Not $_.Server -and -Not $_.Username) { }                               #
          else { $ResultList.Items.Add("$($_.Server) : $($_.Username)") }             #
        }                                                                             #
        $CountLabel.Text = "Count: $($ResultList.Items.Count)"                        #
      }                                                                               # 
      "[Some user] on [some computer]" {                                              # 
        $Username = $UsernameBox.Text                                                 # 
        $Hostname = $HostnameBox.Text                                                 # 
        $global:Sessions = Get-Quser -ServerName $Hostname | Where-Object { $_.UserName -eq $Username }
        $global:Sessions | ForEach-Object {                                           # 
          if (-Not $_.Server -and -Not $_.Username) { }                               #
          else { $ResultList.Items.Add("$($_.Server) : $($_.Username)") }             #
        }                                                                             # 
        $CountLabel.Text = "Count: $($ResultList.Items.Count)"                        #
      }                                                                               # 
      "[Some User] on a PUSH group of computers" {                                    # 
        $Username = $UsernameBox.Text                                                 # 
        $Content = Get-Content "$($Config.Package.Groups)\$($GroupBox.Text).txt"      #
        $Hostnames = New-Object System.Collections.ArrayList                          # 
        $Content | ForEach-Object { Write-Host $_; $Hostnames.Add($_) }               # 
        $Hostnames | ForEach-Object { Write-Host $_ }                                 # 
        $global:Sessions = $Hostnames | Get-QUser | Where-Object {$_.Username -eq $Username }
        $global:Sessions | ForEach-Object {                                           # 
          if (-Not $_.Server -and -Not $_.Username) { }                               #
          else { $ResultList.Items.Add("$($_.Server) : $($_.Username)") }             #
        }                                                                             #  
        $CountLabel.Text = "Count: $($ResultList.Items.Count)"                        #
      }                                                                               # 
      "All Users on a PUSH group of Computers" {                                      # 
        $Content = Get-Content "$($Config.Package.Groups)\$($GroupBox.Text).txt"      # 
        $Hostnames = New-Object System.Collections.ArrayList                          # 
        $Content | ForEach-Object { Write-Host $_; $Hostnames.Add($_) }               # 
        $Hostnames | ForEach-Object { Write-Host $_ }                                 # 
        $global:Sessions = $Hostnames | Get-Quser                                     # 
        $global:Sessions | ForEach-Object {                                           # 
          if (-Not $_.Server -and -Not $_.Username) { }                               #
          else { $ResultList.Items.Add("$($_.Server) : $($_.Username)") }             #
        }                                                                             # 
        $CountLabel.Text = "Count: $($ResultList.Items.Count)"                        #
      }                                                                               # 
      "[Some User] on an AD group of computers" {                                     # 
        $Username = $UsernameBox.Text                                                 # 
        $ADQuery = $Config.Preferences.AD_Preferences.OUs.OU | Where-Object { $_.Name -eq $GroupBox.SelectedItem } | Select-Object -ExpandProperty AD_Query
        $global:Sessions = Get-ADComputer -Filter * -SearchBase $ADQuery | Get-Quser | Where-Object { $_.Username -eq $Username }
        $global:Sessions | ForEach-Object {                                           # 
          if (-Not $_.Server -and -Not $_.Username) { }                               #
          else { $ResultList.Items.Add("$($_.Server) : $($_.Username)") }             #
        }                                                                             # 
        $CountLabel.Text = "Count: $($ResultList.Items.Count)"                        #
      }                                                                               # 
      "All users on an AD group of computers" {                                       # 
        $ADQuery = $Config.Preferences.AD_Preferences.OUs.OU | Where-Object { $_.Name -eq $GroupBox.SelectedItem } | Select-Object -ExpandProperty AD_Query
        $global:Sessions = Get-ADComputer -Filter * -SearchBase $ADQuery | ForEach-Object { $_ | Get-Quser } # -WarningAction SilentlyContinue  #
        $global:Sessions | ForEach-Object {                                           #
          if (-Not $_.Server -and -Not $_.Username) { }                               #
          else { $ResultList.Items.Add("$($_.Server) : $($_.Username)") }             #
        }                                                                             # 
        $CountLabel.Text = "Count: $($ResultList.Items.Count)"                        #
      }                                                                               # 
    }                                                                                 # 
  })                                                                                  # 
                                                                                      #
  $DetailsButton           = New-Object System.Windows.Forms.Button                   #
  $DetailsButton.Text      = "Details"                                                #
  $DetailsButton.Location  = New-Object System.Drawing.Point(320, 100)                #
  $DetailsButton.Size      = New-Object System.Drawing.Size(100, 23)                  #
  $DetailsButton.ForeColor = $Config.ColorScheme.Foreground                                  #
  $DetailsButton.BackColor = $Config.ColorScheme.Background                                  #
  $DetailsButton.FlatStyle = $Config.Design.FlatStyle                                        #
  $DetailsButton.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                             #
  $SessionManagerForm.Controls.Add($DetailsButton)                                    #
                                                                                      #
  $DetailsButton.Add_Click({                                                          #
    $SelectedItem = $ResultList.SelectedItem -split ' +'                              #
    $SelectedSession = $global:Sessions | Where-Object { $_.Server -eq $SelectedItem[0] -and $_.Username -eq $SelectedItem[2] }
    $Message = "Details about $($SelectedSession.Username) on $($SelectedSession.Server)`r`n" +
               "ID: $($SelectedSession.Id)`r`n" +                                     #
               "Name: $($SelectedSession.SessionName)`r`n" +                          #
               "Logon time: $($SelectedSession.LogonTime)`r`n" +                      #
               "State: $($SelectedSession.State)`r`n" +                               #
               "IdleTime: $($SelectedSession.IdleTime)`r`n" +                         #
               "IsCurrentSession: $($SelectedSession.IsCurrentSession)"               #
    [System.Windows.Forms.MessageBox]::Show($Message, $Config.About.Title)            #
  })                                                                                  #
                                                                                      #
  $ShadowButton           = New-Object System.Windows.Forms.Button                    #
  $ShadowButton.Text      = "Shadow"                                                  #
  $ShadowButton.Location  = New-Object System.Drawing.Point(320, 125)                 #
  $ShadowButton.Size      = New-Object System.Drawing.Size(100, 23)                   #
  $ShadowButton.ForeColor = $Config.ColorScheme.Foreground                                   #
  $ShadowButton.BackColor = $Config.ColorScheme.Background                                   #
  $ShadowButton.FlatStyle = $Config.Design.FlatStyle                                         #
  $ShadowButton.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                              #
  $SessionManagerForm.Controls.Add($ShadowButton)                                     #
                                                                                      #
  $ShadowButton.Add_Click({                                                           #
    $SelectedItem = $ResultList.SelectedItem -split ' +'                              #
    $SelectedSession = $global:Sessions | Where-Object { $_.Server -eq $SelectedItem[0] -and $_.Username -eq $SelectedItem[2] }
    $isok = [System.Windows.Forms.MessageBox]::Show("In order to use this feature you must be ON THE PHONE with the client. Are you ON THE PHONE with the client?", "Shadow Confirmation", "YESNO")
    if ($isok -eq "YES") {                                                            #
      $isreallyok = [System.Windows.Forms.MessageBox]::Show("Are you sure? And they're ok with this?", "Extra Confirmation", "YESNO")
      if ($isreallyok -eq "YES") {                                                    #
        Write-Host "Shadowing"                                                        #
        ShadowForm $SelectedSession                                                   #
      }                                                                               #
    }                                                                                 #
  })                                                                                  #
                                                                                      #
  $LogoffButton           = New-Object System.Windows.Forms.Button                    #
  $LogoffButton.Text      = "Logoff"                                                  #
  $LogoffButton.Location  = New-Object System.Drawing.Point(320, 150)                 #
  $LogoffButton.Size      = New-Object System.Drawing.Size(100, 23)                   #
  $LogoffButton.ForeColor = $Config.ColorScheme.Foreground                                   #
  $LogoffButton.BackColor = $Config.ColorScheme.Background                                   #
  $LogoffButton.FlatStyle = $Config.Design.FlatStyle                                         #
  $LogoffButton.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                              #
  $SessionManagerForm.Controls.Add($LogoffButton)                                     #
                                                                                      #
  $LogoffButton.Add_Click({                                                           #
    $SelectedItem = $ResultList.SelectedItem -split ' +'                              #
    $SelectedSession = $global:Sessions | Where-Object { $_.Server -eq $SelectedItem[0] -and $_.Username -eq $SelectedItem[2] }
    $isok = [System.Windows.Forms.MessageBox]::Show("You are about to log off $($SelectedSession.Username) from $($SelectedSession.Server). OK?", "Logoff Confirmation", "OKCancel")
    if ($isok -eq "OK") {                                                             #
      $SelectedSession | Invoke-EndUserSession                                        #
    }                                                                                 #
    $FindButton.PerformClick()                                                        #
  })                                                                                  #
                                                                                      #
  $RefreshButton           = New-Object System.Windows.Forms.Button                   #
  $RefreshButton.Text      = "Refresh"                                                #
  $RefreshButton.Location  = New-Object System.Drawing.Point(320, 175)                #
  $RefreshButton.Size      = New-Object System.Drawing.Size(100, 23)                  #
  $RefreshButton.ForeColor = $Config.ColorScheme.Foreground                                  # 
  $RefreshButton.BackColor = $Config.ColorScheme.Background                                  # 
  $RefreshButton.FlatStyle = $Config.Design.FlatStyle                                        # 
  $RefreshButton.Font      = New-Object System.Drawing.Font($Config.Design.FontSize, $Config.Design.FontSize)                                             #
  $SessionManagerForm.Controls.Add($RefreshButton)                                    # 
                                                                                      # 
  $RefreshButton.Add_Click({                                                          # 
    $FindButton.PerformClick()                                                        #   
  })                                                                                  # 
  #####################################################################################
  # Documentation: Run "All users on [some computer]" dropdown                        #
  # in Session_Manager, only if a computer name is passed in                          #
  # the paramter -C                                                                   #
  #####################################################################################
  if ($Computer) {                                                                    #
    $FindDropdown.SelectedIndex = 0
    $HostnameBox.Text = $Computer
    $Hostname = $HostnameBox.Text                                                     # 
        $global:Sessions = Get-Quser -ServerName $Hostname                            # 
        $global:Sessions | ForEach-Object {                                           # 
          if (-Not $_.Server -and -Not $_.Username) { }                               #
          else { $ResultList.Items.Add("$($_.Server) : $($_.Username)") }             #
        }                                                                             #
        $CountLabel.Text = "Count: $($ResultList.Items.Count)"                        #
  }      
                                                                                      # 
  $SessionManagerForm.ShowDialog()                                                    # 
}                                                                                     #  
#######################################################################################

                                                                               #
###############################################################                       #
# Documentation: This is the shadow session feature. This     #                       #
# brings up a box with a few checkboxes that will ask the     #                       #
# user how the shadow will work (which flags to use) and      #                       #
# then attempts to shadow session for the selected user.      #                       #
###############################################################                       #
function ShadowForm {                                         # SHADOW FORM FUNCTION
  param($Session)                                             #                       #
  $shadow_form = New-Object System.Windows.Forms.Form         # Create a new form object 
  $shadow_form.Text = 'Shadow User Session'                   # The title text will be Shadow User Session
  $shadow_form.Size = New-Object System.Drawing.Size(300,200) # The size of the form is 300 x 200 px
  $shadow_form.StartPosition = 'CenterScreen'                 # appear in the center of the screen
  $shadow_form.TopMost = $true                                # appear on top of everything
  $shadow_form.BackColor = $Config.ColorScheme.Background            # set the background color
  $shadow_form.ForeColor = $Config.ColorScheme.Foreground            # set the foreground color
                                                                                    #
  ###################################################################################
  # Documentation: Control - if you set this option we will add the /control flag   #
  # to the shadow command, which will actually control the users screen, instead of #
  # just viewing the screen                                                         #
  ###################################################################################
  $script:mstscControl = $false                                                     # use the /control flag                                                      
  $mstscControlFlag = New-Object System.Windows.Forms.CheckBox                      # Create a new checkbox object
  $mstscControlFlag.Location = New-Object System.Drawing.Size(10, 20)               # Set the location to 10,20
  $mstscControlFlag.Size = New-Object System.Drawing.Size(250,23)                   # Set the size 
  $mstscControlFlag.Text = "Control"                                                # says "Control"
  $mstscControlFlag.Add_CheckStateChanged({                                         # If a user clicks it:
   $script:mstscControl = $mstscControlFlag.Checked                                # Update $mstscControl
  })                                                                                #
  $shadow_form.Controls.Add($mstscControlFlag)                                      # Add the checkbox to the form
  ###################################################################################

  ###################################################################################
  # Documentation: Consent                                                          #
  # If you set this option we will not add the /noconsentprompt flag to the shadow  #
  # command. Normally, shadow will display a prompt on the user's screen asking if  #
  # they're ok with you shadowing their session, to which they can choose to say no.#
  # If you don't want to give them this option (i.e. view or control their screen   #
  # without their knowing or giving permission) then don't check this box, and the  #
  # script will start a shadow session with the /noconsentprompt flag.              #
  # Note- I intentionally made it very difficult to check this box. You should be   #
  # asking for consent. Don't do things if the end users don't give you their       #
  # consent. Practice ethics. Be a decent human.                                    #
  ###################################################################################
  $script:mstscCP = $true                                                           # use the /noconsentprompt
  $mstscCPFlag = New-Object System.Windows.Forms.CheckBox                           # Create a new checkbox object
  $mstscCPFlag.Checked = $true                                                      # check this box by default.
  $mstscCPFlag.Location = New-Object System.Drawing.Size(10, 43)                    # set the location to 10,43
  $mstscCPFlag.Size = New-Object System.Drawing.Size(250,23)                        # set the size to 250,23
  $mstscCPFlag.Text = "Consent"                                                     # says "Consent"
                                                                                    #
  $HasSeenNoPermissionMessage = $false                                              #
  $mstscCPFlag.Add_CheckStateChanged({                                              # If a user clicks it:
    if ($script:mstscCP) {                                                          #
      if (-Not $HasSeenNoPermissionMessage) {[System.Windows.Forms.MessageBox]::Show("You do not have permission to perform that action.", "ETS requires consent", "OK")}
      $HasSeenNoPermissionMessage = $true                                           #
      $mstscCPFlag.Checked = $true                                                  #
    }                                                                               #
    $script:mstscCP = $mstscCPFlag.Checked                                          # Update $mstscCP
    $HasSeenNoPermissionMessage = $false                                            #
  })                                                                                #
                                                                                    #
  ## How to allow yourself to disable consent checking:                             #
  $CM = New-Object System.Windows.Forms.ContextMenu                                 #
  $DisableCPMenuItem = New-Object System.Windows.Forms.MenuItem                     #
  $DisableCPMenuItem.Text = "Disable Consent Prompt"                                #
  $DisableCPMenuItem.Add_Click({                                                    #
    $yes = [System.Windows.Forms.MessageBox]::Show("Are you sure? You are about to connect to a users personal session without their _explicit_ consent given through a software popup. By clicking 'Yes' you accept full legal and ethical responsiblity for your actions. If you are sure of what you're doing, you may proceed, otherwise click NO.", "Disable consent prompt", "YesNo")
    if ($yes -eq "Yes") {                                                           #
      $script:mstscCP = $false                                                      #
      $mstscCPFlag.checked = $false                                                 #
    }                                                                               #
  })                                                                                #
  $CM.MenuItems.Add($DisableCPMenuItem)                                             #
                                                                                    #
  $mstscCPFlag.ContextMenu = $CM                                                    #
                                                                                    #
  $shadow_form.Controls.Add($mstscCPFlag)                                           # Add this checkbox to the form
  ###################################################################################

  ###################################################################################
  # Documentation: Ask for Login Credentials                                        #
  # When you start a shadow session, it will start as you (the user running this    #
  # script. If you want to start it as another user though, say, techuser, you can  #
  # add the /prompt flag (check this box) and you'll get a popup just like a regular#
  # RDP session asking you for credentials to connect as.                           #   
  ################################################################################### 
  $script:mstscPrompt = $false                                                      # use the /prompt flag
  $mstscPromptFlag = New-Object System.Windows.Forms.CheckBox                       # Create a checkbox for it
  $mstscPromptFlag.Location = New-Object System.Drawing.Size(10, 66)                # The checkbox is at 10,89
  $mstscPromptFlag.Size = New-Object System.Drawing.Size(250,23)                    # and has that size 250,23
  $mstscPromptFlag.Text = "Connect as other user"                                   # the text says that
  $mstscPromptFlag.Add_CheckStateChanged({                                          # If the user checks it:
   $script:mstscPrompt = $mstscPromptFlag.Checked                                  # Update $mstscPrompt
  })                                                                                #
  $shadow_form.Controls.Add($mstscPromptFlag)                                       # Add this checkbox to the form
  ###################################################################################

  ###################################################################################
  # Documentation: Admin Mode                                                       #
  # You connect to the computer. Great. Then you do whatevertheheck you want to it. #   
  ################################################################################### 
  $script:mstscAdmin = $false                                                       # use the /Admin flag
  $mstscAdminflag = New-Object System.Windows.Forms.CheckBox                        # Create a checkbox for it
  $mstscAdminflag.Location = New-Object System.Drawing.Size(10, 89)                 # The checkbox is at 10,89
  $mstscAdminflag.Size = New-Object System.Drawing.Size(250,23)                     # and is that big
  $mstscAdminflag.Text = "Admin"                                                    # the text says "Prompt"
  $mstscAdminflag.Add_CheckStateChanged({                                           # If the user checks it:
   $script:mstscAdmin = $mstscAdminflag.Checked                                    # Update $mstscPrompt
  })                                                                                #
  $shadow_form.Controls.Add($mstscAdminflag)                                        # Add this checkbox to the form
  ###################################################################################

  $okButton = New-Object System.Windows.Forms.Button               # Make an OK Button
  $okButton.Location = New-Object System.Drawing.Point(75,132)     # There
  $okButton.Size = New-Object System.Drawing.Size(75,23)           # that big
  $okButton.Text = 'OK'                                            # it says "OK"
  $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK # When you click it, move on
  $shadow_form.AcceptButton = $okButton                            # Tell the form to move on if 
  $shadow_form.Controls.Add($okButton)                             # Add the button to the form, so it will show up

  $cancelButton = New-Object System.Windows.Forms.Button                   # Create a Cancel button object
  $cancelButton.Location = New-Object System.Drawing.Point(150,132)        # This button will be there
  $cancelButton.Size = New-Object System.Drawing.Size(75,23)               # This button will be that big
  $cancelButton.Text = 'Cancel'                                            # This button says "Cancel"
  $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel # If you click if you click it do that 
  $shadow_form.CancelButton = $cancelButton                                # Tell the form to stop 
  $shadow_form.Controls.Add($cancelButton)                                 # Add the button to the form

  $result = $shadow_form.ShowDialog()                                               # Show this form

  if ($result -eq [System.Windows.Forms.DialogResult]::OK) {                        # If we clicked OK
    $shadow_form.Close()
    $Session | Invoke-ShadowUserSession -control:$script:mstscControl -admin:$script:mstscAdmin -prompt:$script:mstscPrompt -noconsentprompt:(-Not $script:mstscCP) -Force
  }                                  
  #$shadow_form.ShowDialog()                             
}   # If you click the shadow button, it brings up this popup

#######################################################################################
# Documentation: Call Main                                                            #
# To keep my code organized, I put the main form (entryform) in a function called main#
# then i made another function for the shadow form. but, we still need to call main at#
# the end of the script. DONT Delete this please.                                     #
#######################################################################################
Main                                                                                  #
#######################################################################################

#######################################################################################
# Ref:                                                                                #
# Useful things:                                                                      #
# https://www.ipswitch.com/blog/how-to-log-off-windows-users-remotely-with-powershell #
# https://theitbros.com/powershell-gui-for-scripts/                                   #
# https://www.powershellgallery.com/packages/ps2exe/1.0.11                            #
# https://www.educba.com/powershell-add-to-array/                                     #
# http://microsoftplatform.blogspot.com/2013/07/detailed-walkthrough-on-remote-control.html
#                                                                                     #
# Slightly more obscure but maybe still useful:                                       #
# https://stackoverflow.com/questions/53956926/delete-selected-items-from-list-box-in-powershell
# https://stackoverflow.com/questions/47045277/how-do-i-capture-the-selected-value-from-a-listbox-in-powershell
# https://social.technet.microsoft.com/Forums/en-US/48391387-5801-4c9e-a567-bf57aac61ddf/powershell-scripts-check-which-computers-are-turned-on
# https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-if?view=powershell-7.2
# https://dannyda.com/2021/03/13/how-to-fix-shadow-error-the-group-policy-setting-is-configured-to-require-the-users-consent-verify-the-configuration-of-the-policy-setting-on-microsoft-windows-server-2019-remote-desktop-shadow/
#                                                                                     #
# just so its 600 lines long :)                                                       #
#######################################################################################