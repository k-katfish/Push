<#
.SYNOPSIS
  Functions to find user sessions on a remote Windows 10 computer. For which you are an administrator (duh).
.DESCRIPTION
  These functions can be used to find a user on a specified system or a system with a user
.NOTES
  Version:       1.0
  Author:        Kyle Ketchell
  Creation Date: 6/21/22
.EXAMPLE
  Import-Module .\SessionManager.psm1
  Get-UserSession -ComputerName MyOfficeComputer
  Find-UserSession "OU=Computers,DC=myDomain,DC=TLD" * Know your AD structure ;)
#>
[cmdletbinding(DefaultParameterSetName="Manual Entry")]                       # include a non-existing parameter set name as the default one so you can run this without any flags
param(                                                                        #
  [Switch]$P,                                                                 # 
  [Parameter(Mandatory = $true, ParameterSetName = "Computer", Position = 0)] # you must specify -s if you want to run this in silent mode
  [Parameter(Mandatory = $true, ParameterSetName = "User", Position = 0)]     #
  [Alias("S")]                                                                #
  [Switch]$Silent = $false,                                                   #
                                                                              #
  [Parameter(Mandatory = $true, ParameterSetName = "Computer")]               # specify -computer or -c
  [Alias("C")]                                                                #
  [String]$Computer = "",                                                     #
                                                                              #
  [Parameter(Mandatory = $true, ParameterSetName = "User")]                   # specify -user or -u
  [Alias("U")]                                                                #
  [String]$User = "",                                                         #
                                                                              #
  [Parameter()]                                                               #
  [Alias("L")]                                                                #
  [Switch]$light=$false                                                       #
)                                                                             #
############################################################################### Parameters/Flags/Args

function Find-User {
    param([String]$ADSearchString="", [String]$ComputerName="")
    if ($ADSearchString -eq "" -and $ComputerName -eq "") { Write-Host "Please specify either an Active Directory Search String (-ADSearchString `"OU=Computers,DC=Domain,DC=TLD`") or a computer name (-ComputerName `"MyComputer`")"; return -1 }
    if (-Not $ADSearchString -eq "") {
        $ServerList = @()
        Write-Host "Searching '$ADSearchString'"
        $Servers = Get-ADComputer -Filter * -SearchBase $ADSearchString -Properties *
        $ServerList += ($Servers | Select-Object -Property Name).Name
        #ForEach-Object {
        #  $hostfqdn = (( $_ | Out-String ) -split '\n')[3]
        #  $global:ServerList += ($hostfqdn | Out-String).substring(0,$hostfqdn.length - 1)
        #}
        $ServerList | ForEach-Object { Write-Host $_ }
    }
}

Find-User -ADSearchString "OU"

function Get-LoggedOnUser {
    param([String]$ComputerName)
}

#######################################################################################
# Documentation: These variables ought to be global, else bad things will happen.     #
#######################################################################################
                                                                                      #
$global:FindBy = $false # Set true if searching by hostname, false if search by username
$global:Hostname = ''  # The name of the computer we're working on/trying to connect to
$global:UserName = ''  # The name of a particular user that is logged onto that machine
$global:UID = ''       # The UID of that user                                         #
$global:ServerList = @() # the list of servers we'll scan if we're looking for a user #
                                                                                      #
$global:BackgroundColor = 'DimGray'                                                   # ref Colors
$global:ForegroundColor = 'GhostWhite'                                                # 
                                                                                      #
if ($light) {                                                                         # if light mode
  $global:BackgroundColor = "LightGray"                                               # set the background color 
  $global:ForegroundColor = "DarkSlateGray"                                           # set the foreground color
}                                                                                     #
#######################################################################################

if (-Not $Silent) { # IF WE'RE NOT RUNNING IN SILENT MODE:
  #####################################################################################
  # Documentation: Generate a window that prompts the user to enter a                 #
  # hostname to scan for. If the user wants to search a username instead, they can    #
  # toggle to scan for a username instaed, or back to a hostname. Its a lot, but most #
  # of this code is just generating GUI things. And I've stripped out as much gui     #
  # stuff as I can, so what you see is the bare bones of a gui.                       #
  #####################################################################################
  $enterName = New-Object System.Windows.Forms.Form         # Create a new form object
  $enterName.Text = 'Session Manager'                       # The title text will be 'Sesison Manager'
  $enterName.Size = New-Object System.Drawing.Size(300,200) # The size is 300 x 200 px
  $enterName.StartPosition = 'CenterScreen'                 # appear in the center of the screen
  $enterName.Topmost = $true                                # Open this window on top of everything else
  $enterName.BackColor = $global:BackgroundColor            # Set the background of the form
  $enterName.ForeColor = $global:ForegroundColor            # Set the foreground of the form
  
  $okButton = New-Object System.Windows.Forms.Button               # Create an OK button which is:
  $okButton.Location = New-Object System.Drawing.Point(75,120)     # there
  $okButton.Size = New-Object System.Drawing.Size(75,23)           # that big
  $okButton.Text = 'OK'                                            # says "OK"
  $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK # When you click it do the "OK" stuff
  $enterName.AcceptButton = $okButton                              # move on if the user clicks this button
  $enterName.Controls.Add($okButton)                               # Add the button to the form
  
  $cancelButton = New-Object System.Windows.Forms.Button                    # Create a Cancel button
  $cancelButton.Location = New-Object System.Drawing.Point(150,120)         # there
  $cancelButton.Size = New-Object System.Drawing.Size(75,23)                # that big
  $cancelButton.Text = 'Cancel'                                             # says "Cancel"
  $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel  # do that if you click it
  $enterName.CancelButton = $cancelButton                                   # stop if the user clicks it
  $enterName.Controls.Add($cancelButton)                                    # Add the button to the form
  
  $label = New-Object System.Windows.Forms.Label                            # Make a new label
  $label.Location = New-Object System.Drawing.Point(10,20)                  # there
  $label.Size = New-Object System.Drawing.Size(280,20)                      # that big
  $label.Text = 'Enter Username:'                                           # says that
  $enterName.Controls.Add($label)                                           # Add this label to the form
  
  $textBox = New-Object System.Windows.Forms.TextBox                        # Make a new text entry box
  $textBox.Location = New-Object System.Drawing.Point(10,40)                # there
  $textBox.Size = New-Object System.Drawing.Size(260,20)                    # that big
  $enterName.Controls.Add($textBox)                                         # Add this box to the form
  
  $enterOtherNameInstead = New-Object System.Windows.Forms.Button           # Make a new button toggle search mode
  $enterOtherNameInstead.Location = New-Object System.Drawing.Point(10, 70) # there
  $enterOtherNameInstead.Size = New-Object System.Drawing.Size(175,23)      # The button will be 75x23 px
  $enterOtherNameInstead.Text = "Search by Hostname Instead"                # with that text
  $enterOtherNameInstead.Add_Click({                              # When the button gets clicked:
    if ($global:FindBy) {                                         # If we're searching by Hostname
      $label.Text = 'Enter Username:'                             # Change the label to say "Username"
      $enterOtherNameInstead.Text = "Search By Hostname Instead " # Change the button to say "Hostname"
      $global:FindBy = $false                                     # update that we're now searching by username
    } else {                                                      # Otherwise, we're searching by username
      $label.Text = 'Enter Hostname:'                             # change the label to say "Hostname"
      $enterOtherNameInstead.Text = "Search By Username Instead " # Change the button to say "username"
      $global:FindBy = $true                                      # Update that we're searching by hostname
    }                                                             # fi
  })                                                              # end of button behavior
  $enterName.Controls.Add($enterOtherNameInstead)                           # Put it on the form so it shows up
  
  $SearchByResult = $enterName.ShowDialog()                                 # Actually display the form
  
  if ($SearchByResult -eq [System.Windows.Forms.DialogResult]::OK) {        # If we clicked the OK button:
    if ($global:FindBy) {                                                   # If we're searching by hostname:
      $global:Hostname = $textBox.Text                                      # Set $Hostname = [the text box]
    } else {                                                                # If we're searching by username:
      $global:Username = $textBox.Text                                      # Set $Username = [the text box]
    }                                                                       # fi
  } else { exit }                                                           # fi we didn't click the ok button, quit.
} else { # IF WE'RE RUNNING IN SILENT MODE:
  if ($Computer -ne "") {        # if we provided a computer name: 
    $global:FindBy = $true       # set the search mode
    $global:Hostname = $Computer # set the hostname = the computer name
  }                              # 
  if ($User -ne "") {            # if we provided a username:
    $global:FindBy = $false      # set the search mode
    $global:UserName = $User     # set the username
  }                              #
}                                #
##################################

###############################################################
# Documentation: This is the shadow session feature. This     #
# brings up a box with a few checkboxes that will ask the     #
# user how the shadow will work (which flags to use) and      #
# then attempts to shadow session for the selected user.      #
###############################################################
function ShadowForm {                                         # SHADOW FORM FUNCTION
  $shadow_form = New-Object System.Windows.Forms.Form         # Create a new form object 
  $shadow_form.Text = 'Shadow User Session'                   # The title text will be Shadow User Session
  $shadow_form.Size = New-Object System.Drawing.Size(300,200) # The size of the form is 300 x 200 px
  $shadow_form.StartPosition = 'CenterScreen'                 # appear in the center of the screen
  $shadow_form.TopMost = $true                                # appear on top of everything
  $shadow_form.BackColor = $global:BackgroundColor            # set the background color
  $shadow_form.ForeColor = $global:ForegroundColor            # set the foreground color

  ###################################################################################
  # Documentation: Control - if you set this option we will add the /control flag   #
  # to the shadow command, which will actually control the users screen, instead of #
  # just viewing the screen                                                         #
  ###################################################################################
  $global:mstscControl = $false                                                     # use the /control flag                                                      
  $mstscControlFlag = New-Object System.Windows.Forms.CheckBox                      # Create a new checkbox object
  $mstscControlFlag.Location = New-Object System.Drawing.Size(10, 20)               # Set the location to 10,20
  $mstscControlFlag.Size = New-Object System.Drawing.Size(250,23)                   # Set the size 
  $mstscControlFlag.Text = "Control"                                                # says "Control"
  $mstscControlFlag.Add_CheckStateChanged({                                         # If a user clicks it:
    $global:mstscControl = $mstscControlFlag.Checked                                # Update $mstscControl
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
  ###################################################################################
  $global:mstscCP = $true                                                           # use the /noconsentprompt
  $mstscCPFlag = New-Object System.Windows.Forms.CheckBox                           # Create a new checkbox object
  $mstscCPFlag.Checked = $true                                                      # check this box by default.
  $mstscCPFlag.Location = New-Object System.Drawing.Size(10, 43)                    # set the location to 10,43
  $mstscCPFlag.Size = New-Object System.Drawing.Size(250,23)                        # set the size to 250,23
  $mstscCPFlag.Text = "Consent"                                                     # says "Consent"
  $mstscCPFlag.Add_CheckStateChanged({                                              # If a user clicks it:
    $global:mstscCP = $mstscCPFlag.Checked                                          # Update $mstscCP
  })                                                                                #
  $shadow_form.Controls.Add($mstscCPFlag)                                           # Add this checkbox to the form
  ###################################################################################

  ###################################################################################
  # Documentation: Force No Consent                                                 #
  # By default, most computers require that you ask for a similarly-privelaged-user #
  # to give consent (see above) before shadowing their session. (an Admin can       # cf Consent, above^
  # shadow a user's session without consent, but not another admin).                #
  # However, with a registry edit (below) we can change that to force it to happen. # cf ForceNC registry hack
  ###################################################################################
  $global:forceNC = $false                                                          # do the registry hack
  $forceNoConsent = New-Object System.Windows.Forms.CheckBox                        # Create a checkbox for it
  $forceNoConsent.Location = New-Object System.Drawing.Size(10, 66)                 # The checkbox will be: there
  $forceNoConsent.Size = New-Object System.Drawing.Size(250,23)                     # that big
  $forceNoConsent.Text = "Force No Consent (will change Group Policy)"              # say "Force No Consent"
  $forceNoConsent.Add_CheckStateChanged({                                           # If a user checks it:
    $global:forceNC = $forceNoConsent.Checked                                       # Update $forceNC
  })                                                                                #
  $shadow_form.Controls.Add($forceNoConsent)                                        # Add this checkbox to the form
  ###################################################################################

  ###################################################################################
  # Documentation: Ask for Login Credentials                                        #
  # When you start a shadow session, it will start as you (the user running this    #
  # script. If you want to start it as another user though, say, techuser, you can  #
  # add the /prompt flag (check this box) and you'll get a popup just like a regular#
  # RDP session asking you for credentials to connect as.                           #   
  ################################################################################### 
  $global:mstscPrompt = $false                                                      # use the /prompt flag
  $mstscPromptFlag = New-Object System.Windows.Forms.CheckBox                       # Create a checkbox for it
  $mstscPromptFlag.Location = New-Object System.Drawing.Size(10, 89)                # The checkbox is at 10,89
  $mstscPromptFlag.Size = New-Object System.Drawing.Size(250,23)                    # and has that size 250,23
  $mstscPromptFlag.Text = "Ask for Login Credentials"                               # the text says "Prompt"
  $mstscPromptFlag.Add_CheckStateChanged({                                          # If the user checks it:
    $global:mstscPrompt = $mstscPromptFlag.Checked                                  # Update $mstscPrompt
  })                                                                                #
  $shadow_form.Controls.Add($mstscPromptFlag)                                       # Add this checkbox to the form
  ###################################################################################

  ###################################################################################
  # Documentation: Admin Mode                                                       #
  # You connect to the computer. Great. Then you do whatevertheheck you want to it. #   
  ################################################################################### 
  $global:mstscAdmin = $false                                                       # use the /Admin flag
  $mstscAdminflag = New-Object System.Windows.Forms.CheckBox                        # Create a checkbox for it
  $mstscAdminflag.Location = New-Object System.Drawing.Size(10, 112)                # The checkbox is at 10,89
  $mstscAdminflag.Size = New-Object System.Drawing.Size(250,23)                     # and is that big
  $mstscAdminflag.Text = "Admin"                                                    # the text says "Prompt"
  $mstscAdminflag.Add_CheckStateChanged({                                           # If the user checks it:
    $global:mstscAdmin = $mstscAdminflag.Checked                                    # Update $mstscPrompt
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
    #################################################################################
    # Documentation: Registry Hack for Forcing Consent                              #
    # Set the value of HKLM\S\Policies\Ms\WinNT\TS!Shadow = 2 on the remote machine #
    # Other options:                                                                # Ref. dannyda
    #   0. Not Set - Admins can acces Users w/o consent, but need for other admins  #
    #   1. No remote control allowed - shadow won't work                            # I actually think this is 
    #   2. Full Control with consent - Admins can control users with consent        # wrong, I think we can use 
    #   3. Full Control with NO consent - Admins can control without consent        # 2 and not 3 and it will
    #   4. View session with consent - Admins can view users with consent           # work as intended
    #   5. View session with NO consent - Admins can view without consent           #
    ################################################################################# 
    if ($global:forceNC) {                                                          # If we set the noconsent flag
      Invoke-Command -ScriptBlock {                                                 # Run this scriptblock
        $RPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'   # <-- This is the path
        $RKey = 'Shadow'                                                            # <-- This is the name
        Set-ItemProperty -Path $RPath -Name $Rkey -Value 2 -Force                   # <-- Change $Rkey at $Rpath
      } -ComputerName $global:Hostname                                              # run it on $global:Hostname
    }                                                                               #
    #################################################################################

    #################################################################################
    # Documentation - Shadow                                                        #
    # So actually there's no such command as 'shadow' but it's a feature of mstsc   #
    # (Remote Desktop). You use it like mstsc /shadow:SESSIONID                     #
    # By adding some extra flags you can control the behavior of it. I didn't feel  #
    # like line-by-line documenting what I did here, but basically its a nested if  #
    # statement that looks at which flags you wanted to set (with the checkboxes)   #
    # and uses those flags accordingly.                                             #
    # mstsc.exe:                                                                    #
    # /admin - "connects you for administring a remote PC" whatever that means      #
    # /v:<server[:port]> - specify the server to connect to                         #
    # /shadow:[SessionID] - shadow a session                                        #
    # /control - control that shadowed session (interact with their stuff)          #
    # /prompt - Ask for credentials to connect with                                 #
    # /noconsentprompt - don't tell the session we're shadowing that we're shadowing#
    #################################################################################
    switch ($mstscControl) {
     $true { switch ($mstscCP) {
      $true { switch ($mstscPrompt){
       $true { switch ($mstscAdmin) {
        $true  { mstsc.exe /v:$global:Hostname /shadow:$global:UID /control /prompt /restrictedAdmin }
        $false { mstsc.exe /v:$global:Hostname /shadow:$global:UID /control /prompt }}} 
       $false { switch ($mstscAdmin) {
        $true  { mstsc.exe /v:$global:Hostname /shadow:$global:UID /control /restrictedAdmin }
        $false { mstsc.exe /v:$global:Hostname /shadow:$global:UID /control }}}}}
      $false { switch ($mstscPrompt) {
       $true { switch ($mstscAdmin) {
        $true  { mstsc.exe /v:$global:Hostname /shadow:$global:UID /control /prompt /noconsentprompt /restrictedAdmin }
        $false { mstsc.exe /v:$global:Hostname /shadow:$global:UID /control /prompt /noconsentprompt }}}
       $false { switch ($mstscAdmin) {
        $true  { mstsc.exe /v:$global:Hostname /shadow:$global:UID /control /noconsentprompt /restrictedAdmin }
        $false { mstsc.exe /v:$global:Hostname /shadow:$global:UID /control /noconsentprompt }}}}}}}
     $false { switch ($mstscCP) {
      $true { switch ($mstscPrompt){
       $true { switch ($mstscAdmin) {
        $true  { mstsc.exe /v:$global:Hostname /shadow:$global:UID /prompt /restrictedAdmin }
        $false { mstsc.exe /v:$global:Hostname /shadow:$global:UID /prompt }}} 
       $false { switch ($mstscAdmin) {
        $true  { mstsc.exe /v:$global:Hostname /shadow:$global:UID /restrictedAdmin }
        $false { mstsc.exe /v:$global:Hostname /shadow:$global:UID }}}}}
      $false { switch ($mstscPrompt) {
       $true { switch ($mstscAdmin) {
        $true  { mstsc.exe /v:$global:Hostname /shadow:$global:UID /prompt /noconsentprompt /restrictedAdmin }
        $false { mstsc.exe /v:$global:Hostname /shadow:$global:UID /prompt /noconsentprompt }}}
       $false { switch ($mstscAdmin) {
        $true  { mstsc.exe /v:$global:Hostname /shadow:$global:UID /noconsentprompt /restrictedAdmin }
        $false { mstsc.exe /v:$global:Hostname /shadow:$global:UID /noconsentprompt }}}}}}}}
  }                                                               
}   # If you click the shadow button, it brings up this popup

function MainForm {
  ###################################################################################
  # Documentation: This is the main form that the user will be interacting with.    #
  # This displays a list of current sessions, and the option to end those sessions, #
  # or to shadow a session (which just starts the shadow form). Other features      #
  # include the Start a ComputerManagement session with the remote computer.        #
  ################################################################################### 
  $main_form               = New-Object System.Windows.Forms.Form    # Make a new form (this is the main form)
  $main_form.Text          ='$Hostname'                              # The title text says "VCL Logoff Tool
  $main_form.Size          = New-Object System.Drawing.Size(400,200) # The form should be 400x200px
  $main_form.AutoSize      = $true                                   # but also whatever size it wants to be
  $main_form.StartPosition = 'CenterScreen'                          # it will appear in the center of the screen
  $main_form.TopMost       = $true                                   # it will be on top of everything             
  $main_form.BackColor     = $global:BackgroundColor                 # with that background color
  $main_form.ForeColor     = $global:ForegroundColor                 # and that foreground color

  $Name = New-Object System.Windows.Forms.Label                      # Make a new label (plain text)
  if ($global:FindBy) { $Name.Text = "Hostname: '$global:Hostname'"} # if we're searching by hostname say that
  else                { $Name.Text = "Username: '$global:Username'" }# otherwise say that
  $Name.Location = New-Object System.Drawing.Point(0,10)             # The label will be at 0, 10
  $Name.AutoSize = $true                                             # and whatever size it wants to be
  $main_form.Controls.Add($Name)                                     # Add the label to the form so it shows up

  $ListLabel = New-Object System.Windows.Forms.Label          # Add a label
  if ($global:FindBy) { $ListLabel.Text = "Users: " }         # if we're searching by hostname say that
  else                { $ListLabel.Text = "Hosts: " }         # otherwise say that
  $ListLabel.Location = New-Object System.Drawing.Point(0,40) # Make it be at that location
  $ListLabel.AutoSize = $true                                 # and however big it wants to be
  $main_form.Controls.Add($ListLabel)                         # add that label to the form

  $mstscShadowButton = New-Object System.Windows.Forms.Button            # add a shadow button
  $mstscShadowButton.Location = New-Object System.Drawing.Size(400, 63)  # make it there
  $mstscShadowButton.Size = New-Object System.Drawing.Size(120,23)       # and that big
  $mstscShadowButton.Text = "Shadow"                                     # and say that
  $mstscShadowButton.Add_Click({ ShadowForm })                           # if we click it, call the sf function 
  $main_form.Controls.Add($mstscShadowButton)                            # add it to the form

  ###################################################################################
  # Documentation: List of Users or Hosts                                           #
  ###################################################################################
  $List           = New-Object System.Windows.Forms.ListBox  # Make a new List Box 
  $List.Size      = New-Object System.Drawing.Size(300, 46)  # This box will have a width of 300px
  $List.Location  = New-Object System.Drawing.Point(80,40)   # put it at there
  $List.ForeColor = $global:ForegroundColor                  # set the foreground color
  $List.BackColor = $global:BackgroundColor                  # set the background color
                                                                                    #
  $List.Add_SelectedIndexChanged({          # if we change which item we is selected then:
    if ($global:FindBy) {                   # If we're searching by host, then we're selecing a user
      $global:Username = $List.SelectedItem # Update the global variable username accordingly
    } else {                                # otherwise we're searching by users, we're selecting a host
      $global:Hostname = $List.SelectedItem # Update the global variable hostname accordingly
    }                                                                               #
                                                                                    #
    $userinfo = quser /server:$global:Hostname | # Find out who is logged onto $hostname
      Where-Object {$_ -match $global:Username}  # filter out the specific username
    $global:UID = ($userinfo -split ' +')[3]     # save the UID from the quser ouput $UID
    if ($userinfo -like "*Disc*") {              # If the user session is saved to the disc
      $mstscShadowButton.Enabled = $false        #   Disable the shadow button
      $LogoffButton.Enabled = $false             #   Disable the logoff button
    }                                            #   
    else {                                       # Otherwise,
      $mstscShadowButton.Enabled = $true         #   Enable the shadow button
      $LogoffButton.Enabled = $true              #   Enable the logoff button
    }                                            #   
  })                                             #
                                                 #
  $main_form.Controls.Add($List)                 # add the list of logged in users to the main form
  ###################################################################################

  function generateList { # GENERATE THE list of objects that ought to be in the list
    if ($global:FindBy) { # IF WE'RE SEARCHING BY HOSTNAME:
      try {                                               # quser will throw an exception if nobody is logged in
        $Users = quser /server:$global:Hostname           # Get all of the current user sessions  
        Foreach($line in $Users[1..$Users.count]) {       # For each session (skipping the 0th line)
          $User = ($line -split ' +')[1]                  # Get the username
          $List.Items.Add($User)                          # Add that user to the list
        }                                                 #
      } catch {                                            # quser can't find _any_ users- it will complain
        if ($_.Exception.Message -match 'No user exists'){ # "No user exists" means nobody is logged in
          Write-Host "Nobody is logged in. Interesting."   # Write to console that noboy is logged in
        } else {                                           # If the exception says anything else, that's weird
          Write-Host "There is another problem"            # Write to console that there's someting else wrong
          throw $_.Exception.Message                       # throw the exception (crashing the program)
        }                                                 # fi
      }                                                   #
    }                                                     #
    else {                # IF WE'RE SEARCHING BY USERNAME:
      ForEach ($server in $global:ServerList) {           # Iterate through the servers in $ServerList 
        if(test-connection -ComputerName $server -Count 1 -Quiet) { # if it's on:
          try {                                                     # try/catch for quser
            $ErrorActionPreference = 'Stop'                         # whatever tf that is
            $sessioninfo = quser /server:$server |          # get all current user sessions
              Where-Object { $_ -match $global:Username }   # filter by the specific username we're looking for
            if ($sessioninfo -like "*$global:Username*") {  # filter again by the specific username
              if ($sessioninfo -like "*Disc*") {            # If the line says "disc" then it isn't active
                $List.Items.Add("$server -- Inactive")      # Add the user to the list, but mark it as 'inactive'
              } else {                                      # otherwise, the user is logged in like normal
                $List.Items.Add($server)                    # Add that user to the list
              }                                             #
            }                                               #
          } catch {                                         # If quser can't find _any_ users it will complain
            if ($_.Exception.Message -match 'No user exists') { #  If it says "No user exists" then skip it
            } else {                                            # If the exception says anything else that's weird
              Write-Host "There is another problem"             # Write to console that someting else is wrong
              throw $_.Exception.Message                        # throw it up (which likely won't get caught)
  }}}}}}                                                    # fi
  ###################################################################################                   

  ###################################################################################
  # Documentation: Logoff Button                                                    #
  # After selecting a user, you can log them off by clicking the "Logoff" button.   #
  # The main thing is you need to know the ID of the user's session ($global:UID)   #
  # and the name of the computer, and you can use the logoff command to end their   #
  # session. This also removes that user from the list, so you don't try and log    #
  # them off again, or shadow their logged off session.                             #
  ################################################################################### 
  $LogoffButton = New-Object System.Windows.Forms.Button          # Create a logoff button
  $LogoffButton.Location = New-Object System.Drawing.Size(400,40) # the button will be located at 400,40
  $LogoffButton.Size = New-Object System.Drawing.Size(120,23)     # The button will be 120x23 px
  $LogoffButton.Text = "Log off"                                  # the button will say "Logoff"
                                                                  #
  $LogoffButton.Add_Click({                                       # When the user clicks the logoff button:
    # Popup a box that asks "are you sure?"                       # <-- that - vvv sanity check popup vvv
    $answer = [System.Windows.Forms.MessageBox]::Show(            #
      "Are you sure to logoff?",                                  # that is the main message
      "Logoff Confirmation",                                      # that's the title text
      "YesNo",                                                    # the buttons are yes and no
      "Warning"                                                   # its a warning
    )                                                             #
                                                                  #
    if ($answer -eq "yes") {                                      # If the user says "yes":                          
      logoff /server:$Hostname $global:UID                        # actually log off the user
      $List.Items.Remove($List.SelectedItem)                      # Remove the user/host from the list
    }                                                             # otherwise they won't be logged off.
  })                                                              #
                                                                  #
  $main_form.Controls.Add($LogoffButton)                          # Add the button to the form
  #################################################################

  #################################################################
  $refreshButton = New-Object System.Windows.Forms.Button         # Add a refresh button to regenerate the list
  $refreshButton.Text = "Refresh"                                 # make it say that
  $refreshButton.Location = New-Object System.Drawing.Point(0,60) # Make it be at that location
  $refreshButton.Size = New-Object System.Drawing.Size(75,23)     # and have that size
  $refreshButton.Add_Click({                                      # if it gets clicked:
    $List.Items.Clear()                                           # Clear out the list.
    $List.Items.Add("REFRESHING...")                              # make the list say "REFRESHING..."
    generateList                                                  # call generatelist to regenerate the list
    $List.Items.Remove("REFRESHING...")                           # remove the "REFRESHING..." item
  })                                                              # 
  $main_form.Controls.Add($refreshButton)                         # Add the button to the form
  #################################################################

  generateList                   # Fill the list
  $main_form.ShowDialog()        # Finally (and maybe most importantly) Display the form.
}                                                                   #
#####################################################################

if ($global:FindBy) { #IF WE'RE SEARCHING BY HOSTNAME             #
  $status = test-connection -Count 1 -ComputerName $global:Hostname -Quiet  # Send a quick ping to test if it's on
  if (-not($status)) {                                            # if can't connect to computer (status is false)
    [System.Windows.Forms.MessageBox]::Show(                      # show a popup that the computer is offline
      "$Hostname is Offline",                                     # say that
      "PUSH Session Manager",                                     # that is the title
      [System.Windows.Forms.MessageBoxButtons]::OK,               # there's only one button
      [System.Windows.Forms.MessageBoxIcon]::Warning              # its a warning
    )                                                             #
    exit                                                          # quit when the user closes the popup
  }                                                               #
  else {                                                          # If we can connect to the computer
    MainForm                                                      # do the mainform stuff
  }                                                               #
}                                                                 #
else {  #IF WE"RE SEARCHING BY USERNAME                           #
  $global:ServerList = @()                                        # clear out the server list

  function GetServerList {
    #####################################################################################
    # Documentation: This function generates a window that prompts the user to select a #
    # set of hostnames to scan through (or enter their own)                             #
    #####################################################################################
 
    $ServerListForm = New-Object System.Windows.Forms.Form         # Create a new form
    $ServerListForm.Text = 'Secret Tools'                          # The title text will be 'Secret Tools'
    $ServerListForm.Size = New-Object System.Drawing.Size(300,200) # The size of the form is 300 x 200 px
    $ServerListForm.StartPosition = 'CenterScreen'                 # the form will appear in the center
    $ServerListForm.Topmost = $true                                # Open this window on top of everything else
    $ServerListForm.BackColor = $global:BackgroundColor
    $ServerListForm.ForeColor = $global:ForegroundColor

    $okButton = New-Object System.Windows.Forms.Button               # Create an OK button
    $okButton.Location = New-Object System.Drawing.Point(75,120)     # there
    $okButton.Size = New-Object System.Drawing.Size(75,23)           # That big
    $okButton.Text = 'OK'                                            # says "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK # When you click it, move on
    $ServerListForm.AcceptButton = $okButton                         # move on if it's clicked
    $ServerListForm.Controls.Add($okButton)                          # Add the button to the form

    $cancelButton = New-Object System.Windows.Forms.Button                    # Create a Cancel button
    $cancelButton.Location = New-Object System.Drawing.Point(150,120)         # there
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)                # that big
    $cancelButton.Text = 'Cancel'                                             # says "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel  # If you click this just stop
    $ServerListForm.CancelButton = $cancelButton                              # Tell the form to stop
    $ServerListForm.Controls.Add($cancelButton)                               # Add the button to the form

    $label = New-Object System.Windows.Forms.Label           # Make a new label (just plain text)
    $label.Location = New-Object System.Drawing.Point(10,20) # This will appeaer at 10,20
    $label.Size = New-Object System.Drawing.Size(280,20)     # This will have a size of 280x20px
    $label.Text = 'Enter AD SearchBase Query (CN,OU,DC):'    # The label says that
    $ServerListForm.Controls.Add($label)                     # Add this label to the form

    $label = New-Object System.Windows.Forms.Label           # Make a new label (just plain text)
    $label.Location = New-Object System.Drawing.Point(10,40) # This will appeaer at 10,20
    $label.Size = New-Object System.Drawing.Size(280,20)     # This will have a size of 280x20px
    $label.Text = 'Or press Enter to search VCL Servers.'    # The label says that
    $ServerListForm.Controls.Add($label)                     # Add this label to the form

    $textBox = New-Object System.Windows.Forms.TextBox          # Make a new text entry box 
    $textBox.Location = New-Object System.Drawing.Point(10,60)  # below the label
    $textBox.Size = New-Object System.Drawing.Size(260,60)      # that big
    $ServerListForm.Controls.Add($textBox)                      # Add this box to the form

    $SearchByResult = $ServerListForm.ShowDialog()              # Actually display the form
    
    if ($SearchByResult -eq [System.Windows.Forms.DialogResult]::OK) {        # If we clicked the OK button:
      if ($textBox.Text -ne "") {
        (Get-ADComputer -Filter * -SearchBase $textBox.Text -Properties * | Select-Object -Property Name) | 
        foreach-Object {
          $hostfqdn = (( $_ | Out-String ) -split '\n')[3]
          $global:ServerList += ($hostfqdn | Out-String).substring(0,$hostfqdn.length - 1)
        }
      } else {
        #[System.Windows.Forms.MessageBox]::Show(                      # show a popup that you be dumb
        #  "You need to enter a valid AD SearchBase query",            # say that
        #  "PUSH Session Manager",                                     # that is the title
        #  [System.Windows.Forms.MessageBoxButtons]::OK,               # there's only one button
        #  [System.Windows.Forms.MessageBoxIcon]::Warning              # its a warning
        #)                                                             #
        #exit
        (Get-ADComputer -Filter * -SearchBase "OU=Virtual Classroom,OU=Labs,DC=engr,DC=ColoState,DC=EDU" -Properties * | Select-Object -Property Name) | 
        foreach-Object {
          $hostfqdn = (( $_ | Out-String ) -split '\n')[3]
          $global:ServerList += ($hostfqdn | Out-String).substring(0,$hostfqdn.length - 1)
        }
      }
    } else { exit }                                   # fi we didn't click the ok button, then quit the program.
  }
  GetServerList
  MainForm
}

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