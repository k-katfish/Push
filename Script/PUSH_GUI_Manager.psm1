<#
  PUSH GUI Manager
  Author: Kyle Ketchell
  Version: 1.0
  Creation Date: 9/4
#>

function Invoke-GenerateGUI {
  param($Config, [String]$Application, [Switch][Alias("fast")]$StyleOnly)

  Write-Verbose "Invoke-GenerateGUI (Invoke-GG): Generating GUI for $Application with configuration: CS:$($Config.ColorScheme.Name), DS:$($Config.DesignScheme.Name), App:$($Config.About.Name). StyleOnly = $StyleOnly" 1

  if (-Not $StyleOnly) {
    switch ($Application) {
      "PUSH" {
        Write-Verbose "Invoke-GG: Full: 0: Making PUSH GUI form..."
        $GUIForm.ClientSize         = New-Object System.Drawing.Point(900,400)    # Set the size,
        $GUIForm.Text               = $Config.About.Title + " " + $Config.About.Version         # The title, 
        if ($b) { $GUIForm.Text     = $Config.About.Title + " " + $Config.About.Version + " " + $Config.About.Nickname + " - Beta" }
        $GUIForm.Icon               = Convert-Path($Config.Design.Icon)  
        $GUIForm.StartPosition      = 'CenterScreen'                              # the form will appear center screen 
        Write-Verbose "Invoke-GG: Full: 0: Generated PUSH GUI form."

        Write-Verbose "Invoke-GG: Full: 1: Setting size of objects..."
        $SelectLabel.AutoSize  = $true
        $SelectLabDropdown.Size     = New-Object System.Drawing.Size(174, 23)
        $SelectAll.Size             = New-Object System.Drawing.Size(128,23)
        $SelectNone.Size            = New-Object System.Drawing.Size(128,23)
        $MachineList.size           = New-Object System.Drawing.Size(256,300)
        $InstallOnSelMachines.Size  = New-Object System.Drawing.Size(256,23)
        $ManualSectionHeader.Size   = New-Object System.Drawing.Size(256, 25)
        $OrLabel.Size               = New-Object System.Drawing.Size(100, 25)
        $ManualNameTextBox.Size     = New-Object System.Drawing.Size(256, 25)
        $ApplyToManualEntry.Size    = New-Object System.Drawing.Size(256,25)
        $EnterPS.Size               = New-Object System.Drawing.Size(256,25)
        $ScanComputer.Size          = New-Object System.Drawing.Size(256,25)
        $RunExecutablesList.Size    = New-Object System.Drawing.Size(345, 150)
        $SoftwareFilterLabel.Size   = New-Object System.Drawing.Size(70,23)
        $SoftwareFilterTextBox.Size = New-Object System.Drawing.Size(78,23)
        $FixesCheckBox.Size         = New-Object System.Drawing.Size(60,23)
        $SoftwareCheckBox.Size      = New-Object System.Drawing.Size(80,23)
        $UpdatesCheckBox.Size       = New-Object System.Drawing.Size(85, 23)
        $OutputBox.Size             = New-Object System.Drawing.Size(345, 190)
        $DoneLabel.AutoSize = $true
        Write-Verbose "Invoke-GG: Full: 1: Generated Sizes."

        Write-Verbose "Invoke-GG: Full: 2: Setting Locations of Objects..."
        $SelectLabel.location           = New-Object System.Drawing.Point(16,25)
        $SelectLabDropdown.location     = New-Object System.Drawing.Point(97,25)
        $SelectAll.Location             = New-Object System.Drawing.Point(16,50)
        $SelectNone.Location            = New-Object System.Drawing.Point(144,50)
        $MachineList.location           = New-Object System.Drawing.Point(16,73)
        $InstallOnSelMachines.location  = New-Object System.Drawing.Point(16,369)
        $ManualSectionHeader.Location   = New-Object System.Drawing.Point(625, 25) 
        $OrLabel.location               = New-Object System.Drawing.Point(625,50)
        $ManualNameTextBox.location     = New-Object System.Drawing.Point(625,75)
        $ApplyToManualEntry.location    = New-Object System.Drawing.Point(625,100)
        $EnterPS.Location               = New-Object System.Drawing.Point(625,125)
        $ScanComputer.Location          = New-Object System.Drawing.Point(625, 150)
        $RunExecutablesList.location    = New-Object System.Drawing.Point(275,25)
        $SoftwareFilterLabel.Location   = New-Object System.Drawing.Point(276,177)
        $SoftwareFilterTextBox.Location = New-Object System.Drawing.Point(330,174)
        $FixesCheckBox.Location         = New-Object System.Drawing.Point(410,175)
        $SoftwareCheckBox.Location      = New-Object System.Drawing.Point(470,175)
        $UpdatesCheckBox.Location       = New-Object System.Drawing.Point(550, 175)
        $OutputBox.Location             = New-Object System.Drawing.Point(275,200)
        Write-Verbose "Invoke-GG: Full: 2: Generated Locations."

        Write-Verbose "Invoke-GG: Full: 2.5: Calculating Done Label location..."
        $DLX = ($OutputBox.Location.X + 2)
        $DLY = ($OutputBox.Location.Y + $OutputBox.Height + 130)
        $DoneLabel.Location  = New-Object System.Drawing.Point($DLX,$DLY)
        Write-Verbose "Invoke-GG: Full: 2.5: Generated Done Label Location."

        Write-Verbose "Invoke-GG: Full: 3: Setting special properties..."
        $RunExecutablesList.SelectionMode = 'MultiSimple'
        $MachineList.SelectionMode        = 'MultiSimple'
        $OutputBox.ReadOnly               = $true
        $OutputBox.MultiLine              = $true
        $OutputBox.TextAlign              = "Left"
        $OutputBox.WordWrap               = $false
        $OutputBox.ScrollBars             = "Vertical,Horizontal"
        Write-Verbose "Invoke-GG: Full: 3: Configured special properties for objects."
      }
      "RAUserMgr" {

      }
    }
  }

  switch ($Application) {
    "PUSH" {
      Write-Verbose "Invoke-GG Colors: 1.0: Setting up Form object..."
      $GUIForm.BackColor          = $Config.ColorScheme.Background
      Write-Verbose "Invoke-GG Colors: 1.1: Configured Form object" 

      Write-Verbose "Invoke-GG Colors: 2.0: Setting up Background Color for all objects..."
      $SelectLabel.BackColor          = $Config.ColorScheme.Background
      $SelectLabDropdown.BackColor    = $Config.ColorScheme.Background
      $SelectAll.BackColor            = $Config.ColorScheme.Background
      $SelectNone.BackColor           = $Config.ColorScheme.Background
      $MachineList.BackColor          = $Config.ColorScheme.Background
      $InstallOnSelMachines.BackColor = $Config.ColorScheme.Background
      $ManualSectionHeader.BackColor  = $Config.ColorScheme.Background
      $OrLabel.BackColor              = $Config.ColorScheme.Background
      $ManualNameTextBox.BackColor    = $Config.ColorScheme.Background
      $ApplyToManualEntry.BackColor   = $Config.ColorScheme.Background
      $EnterPS.BackColor              = $Config.ColorScheme.Background
      $ScanComputer.BackColor         = $Config.ColorScheme.Background
      $RunExecutablesList.BackColor   = $Config.ColorScheme.Background
      $FixesCheckBox.BackColor        = $Config.ColorScheme.Background
      $SoftwareFilterTextBox.BackColor= $Config.ColorScheme.Background
      $SoftwareCheckBox.BackColor     = $Config.ColorScheme.Background
      $UpdatesCheckBox.BackColor      = $Config.ColorScheme.Background
      $OutputBox.BackColor            = $Config.ColorScheme.Background
      Write-Verbose "Invoke-GG Colors: 2.1: Configured Backcolor for all objects"

      Write-Verbose "Invoke-GG Colors: 3.0: Setting up Foreground Color for all objects..."
      $SelectLabel.ForeColor          = $Config.ColorScheme.Foreground
      $SelectLabDropdown.ForeColor    = $Config.ColorScheme.Foreground
      $SelectAll.ForeColor            = $Config.ColorScheme.Foreground
      $SelectNone.ForeColor           = $Config.ColorScheme.Foreground
      $MachineList.ForeColor          = $Config.ColorScheme.Foreground
      $InstallOnSelMachines.ForeColor = $Config.ColorScheme.Foreground
      $ManualSectionHeader.ForeColor  = $Config.ColorScheme.Foreground
      $OrLabel.ForeColor              = $Config.ColorScheme.Foreground
      $ManualNameTextBox.ForeColor    = $Config.ColorScheme.Foreground
      $ApplyToManualEntry.ForeColor   = $Config.ColorScheme.Foreground
      $EnterPS.ForeColor              = $Config.ColorScheme.Foreground
      $ScanComputer.ForeColor         = $Config.ColorScheme.Foreground
      $RunExecutablesList.ForeColor   = $Config.ColorScheme.Foreground
      $FixesCheckBox.ForeColor        = $Config.ColorScheme.Foreground
      $SoftwareFilterTextBox.ForeColor= $Config.ColorScheme.Foreground
      $SoftwareFilterLabel.ForeColor  = $Config.ColorScheme.Foreground
      $SoftwareCheckBox.ForeColor     = $Config.ColorScheme.Foreground
      $UpdatesCheckBox.ForeColor      = $Config.ColorScheme.Foreground
      $OutputBox.ForeColor            = $Config.ColorScheme.Foreground
      Write-Verbose "Invoke-GG Colors: 3.1: Configured Foreground Color for all objects..."

      Write-Verbose "Invoke-GG Style: 4.0: Setting up Font for all objects..."
      $SelectLabel.Font          = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize) 
      $SelectLabDropdown.Font    = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $SelectAll.Font            = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $SelectNone.Font           = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $MachineList.Font          = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $InstallOnSelMachines.Font = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $ManualSectionHeader.Font  = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $OrLabel.Font              = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $ManualNameTextBox.Font    = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $ApplyToManualEntry.Font   = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $EnterPS.Font              = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $ScanComputer.Font         = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $RunExecutablesList.Font   = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $FixesCheckBox.Font        = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $SoftwareFilterTextBox.Font= New-Object System.Drawing.Font($Config.Design.Fontname, $Config.Design.FontSize)
      $SoftwareFilterLabel.Font  = New-Object System.Drawing.Font($Config.Design.Fontname, $Config.Design.FontSize)
      $SoftwareCheckBox.Font     = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $UpdatesCheckBox.Font      = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $OutputBox.Font            = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      $DoneLabel.Font            = New-Object System.Drawing.Font($Config.Design.FontName, $Config.Design.FontSize)
      Write-Verbose "Invoke-GG Style: 4.1: Configured Font for all objects."

      Write-Verbose "Invoke-GG Style: 5.0: Setting up FlatStyle for all objects..."
      $SelectLabel.FlatStyle          = $Config.Design.FlatStyle
      $SelectLabDropdown.FlatStyle    = $Config.Design.FlatStyle
      $SelectAll.FlatStyle            = $Config.Design.FlatStyle
      $SelectNone.FlatStyle           = $Config.Design.FlatStyle
      #$MachineList.FlatStyle          = $Config.Design.FlatStyle
      $InstallOnSelMachines.FlatStyle = $Config.Design.FlatStyle
      $ManualSectionHeader.FlatStyle  = $Config.Design.FlatStyle
      $OrLabel.FlatStyle              = $Config.Design.FlatStyle
      #$ManualNameTextBox.FlatStyle    = $Config.Design.FlatStyle
      $ApplyToManualEntry.FlatStyle   = $Config.Design.FlatStyle
      $EnterPS.FlatStyle              = $Config.Design.FlatStyle
      $ScanComputer.FlatStyle         = $Config.Design.FlatStyle
      #$RunExecutablesList.FlatStyle   = $Config.Design.FlatStyle
      $FixesCheckBox.FlatStyle        = $Config.Design.FlatStyle
      #$SoftwareFilterTextBox.FlatStyle = $Config.Design.FlatStyle
      $SoftwareFilterLabel.FlatStyle  = $Config.Design.FlatStyle
      $SoftwareCheckBox.FlatStyle     = $Config.Design.FlatStyle
      $UpdatesCheckBox.FlatStyle      = $Config.Design.FlatStyle
      #$OutputBox.FlatStyle            = $Config.Design.FlatStyle
      Write-Verbose "Invoke-GG Style: 4.1: Configured FlatStyle for all objects."

      Write-Verbose "Invoke-GG Style: 5.0: Setting up BorderStyle for all objects..."
      #$SelectLabDropdown.BorderStyle    = $Config.Design.BorderStyle
      #$SelectAll.BorderStyle            = $Config.Design.BorderStyle
      #$SelectNone.BorderStyle           = $Config.Design.BorderStyle
      $MachineList.BorderStyle          = $Config.Design.BorderStyle
      #$InstallOnSelMachines.BorderStyle = $Config.Design.BorderStyle
      $ManualNameTextBox.BorderStyle    = $Config.Design.BorderStyle
      #$ApplyToManualEntry.BorderStyle   = $Config.Design.BorderStyle
      #$EnterPS.BorderStyle              = $Config.Design.BorderStyle
      #$ScanComputer.BorderStyle         = $Config.Design.BorderStyle
      $RunExecutablesList.BorderStyle   = $Config.Design.BorderStyle
      #$FixesCheckBox.BorderStyle        = $Config.Design.BorderStyle
      #$SoftwareFilterTextBox.BorderStyle= $Config.Design.BorderStyle
      #$SoftwareFilterLabel.BorderStyle  = $Config.Design.BorderStyle
      #$SoftwareCheckBox.BorderStyle     = $Config.Design.BorderStyle
      $OutputBox.BorderStyle            = $Config.Design.BorderStyle
      Write-Verbose "Invoke-GG Style: 5.1: Configured BorderStyle for all objects."
    }
    "RAUserMgr" {
      
    }
  }
}