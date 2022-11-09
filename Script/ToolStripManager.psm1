function Invoke-ConfigureTSItem {
    param($TSItem, $Text)
    $TSItem.Text = "&$Text"
    $TSItem.Font = Get-FontSettings
    $TSItem.BackColor = Get-ToolStripBackgroundColor
    $TSItem.ForeColor = Get-ForegroundColor
    $TSItem.Add_MouseEnter({ $this.ForeColor = Get-ToolStripHoverColor })
    $TSItem.Add_MouseLeave({ $this.ForeColor = Get-ForegroundColor })
}
  
function Get-NewTSItem {
    param($Text)
    $NewTSItem = New-Object System.Windows.Forms.ToolStripMenuItem
    Invoke-ConfigureTSItem $NewTSItem -Text $Text
    return $NewTSItem
}
  
function Invoke-TSManageComputer ($ManageComponent) {
    $InputForm               = New-Object System.Windows.Forms.Form
    $InputForm.ClientSize    = New-Object System.Drawing.Size(250,125)
    $InputForm.text          = "$ManageComponent"
    $InputForm.TopMost       = $true
    $InputForm.StartPosition = 'CenterScreen'
    $InputForm.BackColor     = Get-BackgroundColor
    #$InputForm.Icon          = Convert-Path($script:PushConfiguration.Design.Icon)
    #$HostnameLabel            = New-Object System.Windows.Forms.Label   #   # make a label
    #$HostnameLabel.Text       = "Enter Computer Name:"              #   #   # says that
    #$HostnameLabel.height     = 23                                  #   #   # that tall
    #$HostnameLabel.Width      = 150                                 #   #   # that wide
    #$HostnameLabel.Location   = New-Object System.Drawing.Point(10,20)  #   # there
    #$HostnameLabel.Font       = New-Object System.Drawing.Font($script:PushConfiguration.Design.FontName, $script:PushConfiguration.Design.FontSize) # that font
    #$HostnameLabel.Forecolor  = $script:PushConfiguration.ColorScheme.Foreground # that text color
    #$HostnameLabel.BackColor  = $script:PushConfiguration.ColorScheme.Background # that background color
    $HostnameLabel = New-Label -Text "Enter Computer name:" -Location (10, 20)
#    $InputBox          = New-Object System.Windows.Forms.TextBox    #   #   # Make an input text box
#    $InputBox.Height   = 23                                         #   #   # that tall
#    $InputBox.Width    = 200                                        #   #   # that wide
#    $InputBox.Location = New-Object System.Drawing.Point(10,50)     #   #   # there
#    $InputBox.Font     = New-Object System.Drawing.Font($script:PushConfiguration.Design.FontName, $script:PushConfiguration.Design.FontSize)# that font
#    $InputBox.Text     = $ManualNameTextBox.Text                    #   #   # and auto fill the text
    $InputBox = New-TextBox -Location (10, 50) -Size (200, 23)
#    $OKButton              = New-Object System.Windows.Forms.Button #   #   # Make an OK button
#    $OKButton.Height       = 23                                     #   #   # that tall
#    $OKButton.Width        = 50                                     #   #   # that wide 
#    $OKButton.Location     = New-Object System.Drawing.Point(10,80) #   #   # there
#    $OKButton.Font         = New-Object System.Drawing.Font($script:PushConfiguration.Design.FontName, $script:PushConfiguration.Design.FontSize)# that font
#    $OKButton.Text         = "GO"                                   #   #   # it says that
#    $OKButton.ForeColor = $script:PushConfiguration.ColorScheme.Foreground  #
    $OKButton = New-Button -Text "GO" -Location (10, 80) -Size (50, 23)
    $OKButton.Add_Click({
      $TSManageComputerName = $InputBox.Text
      $InputForm.Close()
      switch ($ManageComponent) {
        "scan" { Start-Process powershell -ArgumentList "Powershell $PSScriptRoot\Scan_Host.ps1 -Hostname $TSManageComputerName" -WindowStyle:Hidden}
        "explorer.exe" { Start-Process \\$TSManageComputerName\c$ }
        "lusrmgr.msc" { Start-Process Powershell -ArgumentList "Powershell lusrmgr.msc /computer:$TSManageComputerName" -NoNewWindow }
        "gpedit.msc" { Start-Process Powershell -ArgumentList "Powershell gpedit.msc /gpcomputer: $TSManageComputerName" -NoNewWindow }
        "gpupdate" { Start-Process Powershell -ArgumentList "Powershell Invoke-Command -ScriptBlock { gpupdate /force } -ComputerName $TSManageComputerName" -NoNewWindow }
        "compmgmt.msc" { Start-Process Powershell -ArgumentList "Powershell compmgmt.msc /computer:$TSManageComputerName" -NoNewWindow }
        "restart" { Restart-Computer -ComputerName $TSManageComputerName -Credential $(Get-Credential -Message "Please provide credentials to Restart this Computer." -Username "$env:USERDOMAIN\$env:USERNAME") -Force }
        "shutdown" { Stop-Computer -ComputerName $TSManageComputerName -Credential $(Get-Credential -Message "Please provide credentials to Shut Down this Computer." -Username "$env:USERDOMAIN\$env:USERNAME") -Force }
      }
    })
    $InputBox.Add_KeyDown({ if ($PSItem.KeyCode -eq "Enter") { $OKButton.PerformClick() }})
    $InputBox.Add_KeyDown({ if ($PSItem.KeyCode -eq "Escape") { $InputForm.Close() }})
    $InputForm.Add_KeyDown({ if ($PSItem.KeyCode -eq "Escape") { $InputForm.Close() }})
    $InputForm.Controls.AddRange(@($HostnameLabel,$InputBox,$OKButton))
    $InputForm.ShowDialog()
}
  
function Invoke-TSHelpReader ($HelpOption) {
    $HelpForm               = New-Object System.Windows.Forms.Form
    $HelpForm.text          = "Push Help"
    $HelpForm.AutoSize      = $true
    $HelpForm.TopMost       = $true
    $HelpForm.StartPosition = 'CenterScreen'
    $HelpForm.BackColor     = $script:PushConfiguration.ColorScheme.Background
    $HelpForm.Icon          = Convert-Path($Config.Design.Icon)
    $HelpText            = New-Object System.Windows.Forms.TextBox
    $HelpText.Location   = New-Object System.Drawing.Point(0,0)
    $HelpText.Size       = New-Object System.Drawing.Size(700,300)
    $HelpText.Font       = New-Object System.Drawing.Font($script:PushConfiguration.Design.FontName, $script:PushConfiguration.Design.FontSize)
    $HelpText.ForeColor  = $script:PushConfiguration.ColorScheme.Foreground
    $HelpText.BackColor  = $script:PushConfiguration.ColorScheme.Background
    $HelpText.ReadOnly   = $true
    $HelpText.MultiLine  = $true
    $HelpText.ScrollBars = 'Vertical'
    Get-Content "$($script:PushConfiguration.Location.Documentation)\$HelpOption" | ForEach-Object {
      $HelpText.AppendText("$_`r`n")
    }
    $HelpForm.Controls.Add($HelpText)
    $HelpForm.ShowDialog()
}
  

function RefreshToolStrip {
    param($ToolStrip)#$Config, [String]$Application)
 
    $ToolStrip.BackColor = Get-BackgroundColor
    $ToolStrip.ForeColor = Get-ForegroundColor

    $ToolStrip.Items | ForEach-Object {
        Invoke-ConfigureTSItem $_ $_.Text.Substring(1)
        $_.DropDownItems | ForEach-Object {
            Invoke-ConfigureTSItem $_ $_.Text.SubString(1)
        }
    }
    
#    $script:PushConfiguration = $Config
  
#    log "PUSHApps Tool Strip: Refreshing Tool Strip..." 0
#    $ToolStrip.BackColor = $script:PushConfiguration.ColorScheme.ToolStripBackground
#    $ToolStrip.ForeColor = $script:PushConfiguration.ColorScheme.Foreground
#    log "PUSHApps Tool Strip: Refreshed Tool Strip." 0
  
    <##############################################################################>
  
  
#    $ToolStripFileItem = $ToolStrip.Items.Item($ToolStrip.GetItemAt(5, 2))
#    Invoke-ConfigureTSItem $ToolStripFileItem $ToolStripFileItem.Text.Substring(1)
    
#    $ToolStripFileItem.DropDownItems | ForEach-Object {
#      Invoke-ConfigureTSItem $_ $_.Text.Substring(1)
#    }
#    log "PUSHApps Tool Strip: Refreshed File Menu Item." 0
  
    <##############################################################################>
  
  
#    log "PUSHApps Tool Strip: Refreshing Remote Computer menu item." 0
#    $ToolStripRemoteItem = $ToolStrip.GetNextItem($ToolStripFileItem, 16)
#    Invoke-ConfigureTSItem $ToolStripRemoteItem $ToolStripRemoteItem.Text.Substring(1)
  
#    $ToolStripRemoteItem.DropDownItems | ForEach-Object {
#      Invoke-ConfigureTSItem $_ $_.Text.Substring(1)
#    }
#    log "PUSHapps ToolStrip: Refreshed Remote Computer menuitem & dropdownitems" 0
##  
#    <##############################################################################>
#  
#    log "PUSHapps ToolStrip: Refreshing Help menuitems..." 0
#    $ToolStripHelpItem = $ToolStrip.GetNextItem($ToolStripRemoteItem, 16)
#    Invoke-ConfigureTSItem $ToolStripHelpItem $ToolStripHelpItem.Text.Substring(1)
#  
#    $ToolStripHelpItem.DropDownItems | ForEach-Object {
#      Invoke-ConfigureTSItem $_ $_.Text.Substring(1)
#    }
#    log "PUSHapps ToolStrip: Refreshed Help Menu and dropdown items." 0
}