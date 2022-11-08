param([Parameter()][Alias("Configure")][String]$ConfigurationFile="\\software.engr.colostate.edu\software\ENS\Push_2.0\Configuration.xml")
#######################################################################################
# SERVER LOGOFF TOOL                                                                  #
#                                                                                     #
# Author: Kyle Ketchell (Software Guru)                                               #
#         kkatfish@cs.colostate.edu                                                   #
#         5/18/2022                                                                   #
#######################################################################################

#=====================================================================================#
# TODO: 
# - Refactor to be broke into functions, for greater interoperability with SessionManager
#=====================================================================================#

#######################################################################################
# Documentation: The basic structure of this script is:                               #
#                                                                                     #
# 1. Ask the person running this script for a username to scan for                    # cf Part 1, ~40 - ~100
# 2. Ask the person running this script which set of servers to scan                  # cf Part 1, ~40 - ~100 
# 3. Scan those servers for that username                                             # cf Driver code in Part 2, ~150 - ~173, also ref ipswitch.com
# 4. Display all servers that user is currently logged into                           # cf Part 2, ~100 - ~200
# 5. Logoff the user from the server that we (running the script) select              # cf Driver code in Part 2, ~190 - ~200, also ref ipswitch.com                   
#######################################################################################

Add-Type -AssemblyName System.Windows.Forms   #Initialize the powershell gui          # ref itbros.com
Add-Type -AssemblyName System.Drawing         #I'm pretty sure this is also important # ref itbros.com

[xml]$Conf = Get-Content($ConfigurationFile)

if (Test-Path P:\Build) {
  
} else {
  New-PSDrive P -Root $Conf.P.Location.P_drive -Credential $Conf.P.Preferences.Username -PSProvider Filesystem
}
#######################################################################################
# Documentation: This script comes in 2 parts. This is part 1, where it will ask the  #
# person running the script to enter a username which will be scanned for.            #
#                                                                                     #
# Probably 90% of this script is literally just generating GUI things to make it easy #
# to interact with this script. the important stuff is documented with ## so you know #
# what to look for. # is probably useless, like just generating visual objects.       #
#######################################################################################

$entry_form = New-Object System.Windows.Forms.Form                        # Create a new form object (A window)
$entry_form.Text = 'VCL Logoff Tool'                                      # The title text will be VCL Logoff Tool
$entry_form.Size = New-Object System.Drawing.Size(300,200)                # The size of the form is 300 x 200 px
$entry_form.StartPosition = 'CenterScreen'                                # --super handy - the form will appear in the center of the screen

$okButton = New-Object System.Windows.Forms.Button                        # The form has an OK button, you click this to tell the program to move on
$okButton.Location = New-Object System.Drawing.Point(75,120)              # The OK button will be at location 75, 120 (0,0 is the top left corner, 300,200 is the bottom right)
$okButton.Size = New-Object System.Drawing.Size(75,23)                    # The OK button is 75px long by 23px tall
$okButton.Text = 'OK'                                                     # The OK button says "OK"
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK          # When you click it, the variable sys.win.forms.diagresult will be set to "OK"
$entry_form.AcceptButton = $okButton                                      # Tell the form to move on iff the user clicks this button
$entry_form.Controls.Add($okButton)                                       # Add the button to the form, so it will show up

$cancelButton = New-Object System.Windows.Forms.Button                    # Create a Cancel button object
$cancelButton.Location = New-Object System.Drawing.Point(150,120)         # This button will be at location 150, 200
$cancelButton.Size = New-Object System.Drawing.Size(75,23)                # This button will be 75px wide by 23px tall
$cancelButton.Text = 'Cancel'                                             # This button says "Cancel"
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel  # If you click this, the variable sys.win.forms.diagresult will be set to "Cancel" 
$entry_form.CancelButton = $cancelButton                                  # Tell the form to stop iff the user clicks this button
$entry_form.Controls.Add($cancelButton)                                   # Add the button to the form

$label = New-Object System.Windows.Forms.Label                            # Make a new label (just text)
$label.Location = New-Object System.Drawing.Point(10,20)                  # This will appeaer at 10,20
$label.Size = New-Object System.Drawing.Size(280,20)                      # This will have a size of 280x20px
$label.Text = 'Enter Username:'                                           # The label says "Enter Username:"
$entry_form.Controls.Add($label)                                          # Add this label to the form
 
$textBox = New-Object System.Windows.Forms.TextBox                        # Make a new text entry box where the user will enter the username they want to find
$textBox.Location = New-Object System.Drawing.Point(10,40)                # This text box will be below the label, so 10, 40
$textBox.Size = New-Object System.Drawing.Size(260,20)                    # This text box will have a height of 20, and a width of 260px
$entry_form.Controls.Add($textBox)                                        # Add this text entry box to the form
 
$ServerCollectionList = New-Object system.Windows.Forms.ComboBox          # Create a new dropdown
$ServerCollectionList.text = “VCL”                                        # The text will say "VCL"
$ServerCollectionList.width = 170                                         # The dropdown has a width of 170
$ServerCollectionList.autosize = $true                                    # I guess its also automatic so whatever lol
$Groups = Get-ChildItem $Conf.P.Location.Groups                           # Get the items in the groups folder
$Groups | ForEach-Object {$ServerCollectionList.Items.Add($_.Name.SubString(0, $_.Name.Length-4))}            # Add the items in the dropdown list
$ServerCollectionList.SelectedIndex = 0                                   # Select the default value
$ServerCollectionList.location = New-Object System.Drawing.Point(10,60)   # Where the list will be
$entry_form.Controls.Add($ServerCollectionList)                           # Add the list to the form

$entry_form.Topmost = $true                                               # Open this window on top of everything else
$entry_form.Add_Shown({$textBox.Select()})                                # ?? best guess, it tells the form to make the text box visible and not hide it, but I could be wrong.
$result = $entry_form.ShowDialog()                                        # Actually display this window/make it appear/present it to the user

$User = ''  #if this isn't here, the scope of user will be that thar if statement. so keep this here, otherwise $user will only exist for 1 line, and that would be sad
$ServerCollection = ''  #if this isn't here, the scope of servercollection will be that thar if statement. so keep this here, otherwise $servercollection will only exist for 1 line, and that would be sad

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {  # If we clicked the OK button (see line 13) then:
    $User = $textBox.Text                                   #   Set $User = [whatever we entered into the text box]
    $ServerCollection = $ServerCollectionList.SelectedItem  #   Set $ServerCollection = [Whatever we selected from the dropdown]
} else { exit }                                             # Otherwise... quit

#######################################################################################
# Documentation: This script comes in 2 parts. This is part 2, where it will actually #
# scan for the username, and bring up a menu asking which user you want to kill.      #
#######################################################################################
$Servers = Get-Content ($Conf.P.Location.Groups + "\" + $ServerCollection + ".txt")
Write-Host $Servers

$main_form = New-Object System.Windows.Forms.Form          # Make a new form (this is the main logoff form)
##Powershell is bs and I hAtE it                           # <-- that
$main_form.Text ='VCL Logoff Tool'                         # The title text says "VCL Logoff Tool
$main_form.Size = New-Object System.Drawing.Size(400,200)  # The form should be 400x200px
$main_form.AutoSize = $true                                # but also whatever size it wants to be works too
$main_form.StartPosition = 'CenterScreen'                  # it will appear in the center of the screen

$uname = New-Object System.Windows.Forms.Label             # Make a new label (plain text)
$uname.Text = "Username: $User"                            # The label says Username: [whatever the variable $User is]
$uname.Location = New-Object System.Drawing.Point(0,10)    # The label will be at 0, 10
$uname.AutoSize = $true                                    # and whatever size it wants to be, like, who even cares about counting pixels am i right?
$main_form.Controls.Add($uname)                            # Add the label to the form so it shows up

$svr = New-Object System.Windows.Forms.Label               # Make another new label ... actually I think this one's hidden under the list lol
$svr.Text = "Server: "
$svr.Location = New-Object System.Drawing.Point(0,40)
$svr.AutoSize = $true
$main_form.Controls.Add($svr)

#######################################################################################
# Documentation: We first need to find out which servers the user is actually logged  #
# in to, then we'll add those to the list box
#######################################################################################

$LoggedInList = New-Object System.Windows.Forms.ListBox        # Make a new List Box that will have a list of all of the available servers in it
$LoggedInList.Width = 300                                      # This box will (in theory) have a width of 300px

#######################################################################################
# Documentation: a lot of this script is just gui stuff. this next section though is  #
# actually the useful part that will scan a server to see if someone's logged in.     #
# Specifically the ## stuff, that's really the meat and bones of the script           #
#######################################################################################

#decide if quser is quser or sysnative\quser.exe
try {
  quser
} catch {
  if ($_ -like "*is not recognized*"){
    Set-Alias -Name quser -Value C:\Windows\Sysnative\quser.exe
    Set-Alias -Name logoff -Value C:\Windows\Sysnative\logoff.exe
  }
}

## This is the actually useful part, that scans each server in the list of servers and asks if a user is logged in or not
Foreach ($Server in $Servers) {                                             # Iterate through the array of $Servers
  Write-Host "Looking at $Server for $User"                                 # Log to the console which server we're scanning and which user we're scanning for
  $status = test-connection -Count 1 -ComputerName $Server -Quiet           # Send a quick ping to see if the server is even on
  if ($status) {                                                            # If there IS a response from the server ($status = $true)
    $ErrorActionPreference = 'Stop'                                         # whatever this is?
    try {                                                                  ##   Surround this with a try-catch, bc quser will throw an exception if nobody is logged in
      ## Find all sessions matching the specified username                 ##     <-- that
      $sessions = quser /server:$Server | Where-Object {$_ -match $User}   ##     get all sessions on the computer "quser /server:$Server" and filter them to find the desired user "| Where-Object {$_ -match $User}" and store that/them in $sessions
      $sessions                                                            ##     print $sessions to the console, mostly for debugging but i'll leave this here just in case someone's curious 
      if ($sessions -like "*$User*" ) {                                    ##     If this isn't here, every server will get added to the list, so only add the server to the list if the *actual* user is *actually* logged on
        $sessionIds = ($sessions -split ' +')[2]                           ##       get the session id "$sessions -split ' +' [2]" from the session object
        if ($sessionIds -eq "") { continue }                               ##       if there isn't an actual session id "if the session id == ''" then just move on to the next server "continue"
        $LoggedInList.Items.Add($Server)                                   ##       The user actually exists! Add that server to the list of servers that will show up.
      }                                                                    ##     fi
    } catch {                                                              ##   If quser can't find _any_ users logged on it will throw an exception
      if ($_.Exception.Message -match 'No user exists') {                  ##     If that exception says something like "Error No user exists" then nobody is logged in
        Write-Host "Nobody is logged in. Interesting."                     ##       Write to console that noboy is logged in
      } else {                                                             ##     If the exception says anything else, that's weird
        Write-Host "There is another problem"                              ##       Write to console that there's someting else wrong
        throw $_.Exception.Message                                         ##       throw a new exception (that likely won't get caught, crashing the program)
      }                                                                    ##     fi
    }                                                                      ##   end of the useful code
  } else { Write-Host "Cannot connect to $Server" }                         # If there wasn't a response from the server, don't do any of that ^ and just write that we couldn't connect
}

#######################################################################################
# Documentation: What follows is more gui stuff. lots of long kinda useless lines.    #
#######################################################################################

$LoggedInList.Location  = New-Object System.Drawing.Point(60,40)            # Now that we've got the list of servers the user is actually logged into set up, put it at 60,40
$main_form.Controls.Add($LoggedInList)                                      # and add that to the main_form

$LogoffButton = New-Object System.Windows.Forms.Button                      # Create a new button object
$LogoffButton.Location = New-Object System.Drawing.Size(400,40)             # the button will be located at 400,40
$LogoffButton.Size = New-Object System.Drawing.Size(120,23)                 # The button will be 120x23 px
$LogoffButton.Text = "Log off"                                              # the button will say "Logoff"
$LogoffButton.Enabled = $false                                              # Disable the button at first
$main_form.Controls.Add($LogoffButton)                                      # Add the button to the form

#######################################################################################
# Documentation: We just created a button, great! Now we actually need to so something#
# when the button gets clicked. so we'll add a click behavior (which contains SUPER   #
# USEFUL logoff code). More gui stuff with #, but again the useful meat/bones is      #
# marked with a ##                                                                    #
#######################################################################################

$LogoffButton.Add_Click({                                      # When the user clicks the logoff button, do this:
  # Popup a box that asks "are you sure?"                      # <-- sanity check popup
  $answer = [System.Windows.Forms.MessageBox]::Show( "Are you sure you want to log off $User?", " Removal Confirmation", "YesNoCancel", "Warning" )
  
  if ($answer -eq "yes") {                                                         # If the user says "yes" to the sanity check popup then:                          
    $SelectedServer = $LoggedInList.SelectedItem                                   # $SelectedServer is the one we hilighted in the list of available servers generated earlier
    Write-Host "$SelectedServer"                                                   # Write to console which server we're going to act on
    try {                                                                         ## Surround this with a try-catch, because quser will still throw an exception if no users are logged in
      ## Find all sessions matching the specified username                        ##   <--
      $sessions = quser /server:$SelectedServer | Where-Object {$_ -match $User}  ##   find all sessions on the computer "quser /server:$SS" and find our user "| Where-Object {$_ -match $User} 
      ## Parse the session IDs from the output                                    ##   <--
      $sessionIds = ($sessions -split ' +')[2]                                    ##   get the session id (console, or rdp-#01) and put it in the $sessionIDs
      Write-Host "Found $(@($sessionIds).Count) user login(s) on computer."       ##   write to console how many times the user was logged on
      ## Loop through each session ID and pass each to the logoff command         ##   <--
      $sessionIds | ForEach-Object {                                              ##   for every session id we have:
        Write-Host "Logging off session id [$($_)]..."                            ##     Write to console that we're logging off that session id
        logoff /server:$SelectedServer $_                                         ##     then actually log off the user
      }                                                                           ##   if the user doesn't get successfully logged off (i've never actually had this happen, but i bet logoff would throw an error/exception, which wouldn't get caught, and this would crash
    } catch {                                                                     ## IF quser throws an exception (which would be weird at this point because we've already scanned for this earlier, but just in case or whatever)
      if ($_.Exception.Message -match 'No user exists') {                         ##   if the exception message contains "no user exists" then its from quser, and it just means the user is logged off
        Write-Host "The user is not logged in."                                   ##     Write to console that the user isn't logged in
      } else {                                                                    ##   if it doesn't contain that then something else is weird:
        throw $_.Exception.Message                                                ##     throw a new exception (that won't get caught, crashing the program)
      }                                                                            #   fi
    }                                                                              # yrt
    $LoggedInList.Items.Remove($LoggedInList.SelectedItem)                         # Remove the server from the list of possible servers to log the user out of
  }                                                                                # if the user said no or cancel then they won't be logged off. no need to explicitly state that in the code just don't add any behavior for those 2 things
})                                                             # pheweph. that's a whole lot for one little button :)

$LoggedInList.Add_SelectedIndexChanged({           # If the user clicks the list
  $LogoffButton.Enabled = $true     # enable the logoff button
})                                 

$main_form.ShowDialog()        # Finally (and maybe most importantly) Display the message box.

#######################################################################################
# Ref:                                                                                #
# Useful things:                                                                      #
# https://www.ipswitch.com/blog/how-to-log-off-windows-users-remotely-with-powershell #
# https://theitbros.com/powershell-gui-for-scripts/                                   #
# https://www.powershellgallery.com/packages/ps2exe/1.0.11                            #
# https://www.educba.com/powershell-add-to-array/                                     #
#                                                                                     #
# Slightly more obscure but maybe still useful:                                       #
# https://stackoverflow.com/questions/53956926/delete-selected-items-from-list-box-in-powershell
# https://stackoverflow.com/questions/47045277/how-do-i-capture-the-selected-value-from-a-listbox-in-powershell
# https://social.technet.microsoft.com/Forums/en-US/48391387-5801-4c9e-a567-bf57aac61ddf/powershell-scripts-check-which-computers-are-turned-on
# https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-if?view=powershell-7.2
#                                                                                     #
#######################################################################################