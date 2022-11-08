$script:Config = [XML](Get-Content $PSScriptRoot\config.xml)
$script:SelectedColorScheme = "Dark"
$script:SelectedDesignScheme = "Classic"

function Get-GroupsFolderLocation {
  return $script:Config.Configuration.GroupsFolderLocation.Location
}

function Get-SoftwareFolderLocation {
  return $script:Config.Configuration.SoftwareFolderLocation.Location
}

function Get-BackgroundColor {
  return $script:Config.Configuration.$script:SelectedColorScheme.BackColor
}

function Get-ForegroundColor {
  return $script:Config.Configuration.$script:SelectedColorScheme.ForeColor
}

function Get-FontSettings {
  return New-Object System.Drawing.Font($script:Config.Configuration.$script:SelectedDesignScheme.FontName, $script:Config.Configuration.$script:SelectedDesignScheme.FontSize)
}

function Set-ColorScheme ($SchemeName) {
  $script:SelectedColorScheme = $SchemeName
}
















$script:ConfigurationFileLocation = ""

function Invoke-ChangePUSHConfigurationSourceFile {
  param($ConfigurationFile)
  $script:ConfigurationFileLocation = $ConfigurationFile
}

function Get-PUSH_Configuration {
  param($ConfigurationFile, [String]$ColorScheme, [String]$Design, [String]$Application)
#  Write-Host "Getting Configuration from $ConfigurationFile, $ColorScheme Colors, $Design Design, and the Application $Application"
  if ($ConfigurationFile) {
    $script:ConfigurationFileLocation = $ConfigurationFile
  }

  try {
    [xml]$Configuration_Settings = Get-Content $script:ConfigurationFileLocation
  } catch {
    Write-Host "It appears that PUSH_Config_Manager has not yeet been configured with a proper configuration file. Please call Get-PUSH_Configuration with the path to a valid Configuration file, or Invoke-ChangePUSHConfigurationSourceFile with a valid configuration file path to set the path to a valid configuration file."
  }

  $Gui_Config = $Configuration_Settings.Configuration.GUI_Configuration

  $Colors = $Gui_Config.ColorSchemes.ColorScheme | Where-Object { $_.Name -eq $ColorScheme } 
  #Write-Host "Selected Scheme: $($Colors.Name)"

  $Style = $Gui_Config.Designs.Design | Where-Object { $_.Name -eq $Design } 
  #Write-Host "Selected Style: $($Style.Name)"

  $ApplicationConfiguration = $Configuration_Settings.Configuration.Applications.Application | Where-Object { $_.About.Name -eq $Application }
  #Write-Host "Selected Package: $($ApplicationConfiguration.About.Name)"

  #Write-Host "Generating Color Preferences Object"
  $CS = New-Object PSObject -Property @{
    Name                = $Colors.Name
    Background          = $Colors.Background
    Foreground          = $Colors.Foreground
    ToolStripBackground = $Colors.ToolStripB
    ToolStripHover      = $Colors.ToolStripH
    Success             = $Colors.Success
    Warning             = $Colors.Warning
    Error               = $Colors.Error
  }
  
  #Write-Host $CS.Name

  #Write-Host "Generating Design Preferences Object"
  $D = New-Object psobject -Property @{
    Name = $Style.Name
    Icon = $Style.Push_Icon
    Scan_Host_Icon = $Style.SH_Icon
    FlatStyle = $Style.FlatStyle
    BorderStyle = $Style.BorderStyle
    FontName = $Style.FontName
    FontSize = $Style.FontSize
  }
  #Write-Host $D.Name

  #Write-Host "Generating About Application Object"
  $About_Application = New-Object psobject -Property @{
    Name = $ApplicationConfiguration.About.Name
    Version = $ApplicationConfiguration.About.Version
    Nickname = $ApplicationConfiguration.About.Nickname
    Author = $ApplicationConfiguration.About.Author
    Title = $ApplicationConfiguration.About.Title
    Description = $ApplicationConfiguration.About.Description
    Company = $ApplicationConfiguration.About.Company
    Creation_Date = $ApplicationConfiguration.About.Creation_Date
    Compile_Date = $ApplicationConfiguration.About.Compile_Date
    Compile_User = $ApplicationConfiguration.About.Compile_User
  }
  #Write-Host $About_Application.Name

  #Write-Host "Generating Application Package Data"
  $Application_Package = New-Object PSObject -Property @{
    Location = $ApplicationConfiguration.Package.Location
    Script = $ApplicationConfiguration.Package.Script
    Documentation = $ApplicationConfiguration.Package.Documentation
    Logs = $ApplicationConfiguration.Package.Logs
    Build = $ApplicationConfiguration.Package.Build
    Media = $ApplicationConfiguration.Package.Media
    Groups = $ApplicationConfiguration.Package.Groups
    Software = $ApplicationConfiguration.Package.Software
  }
  #Write-Host $Application_Package.Location

  $Prefs = $Configuration_Settings.Configuration.Applications.Preferences

  #Write-Host "Generating Application Preferences"
  $Application_Preferences = New-Object psobject -Property @{
    Default_Username = $Prefs.Default_Username
    AD_Preferences = $Prefs.AD_Preferences
  }
  #Write-Host $Application_Preferences.Default_Username

  $Configuration = New-Object PSObject -Property @{
    ColorScheme = $CS
    Design = $D
    About = $About_Application
    Package = $Application_Package
    Preferences = $Application_Preferences
  }

  return $Configuration
}

function Update-PUSH_Configuration {
  param($Config)
  #$Config
}

function Set-PUSH_Configuration {
  param(
    [Parameter(Mandatory=$true)]
    $Config,

    [String]
    [Alias("ColorScheme")]
    $NewColorScheme,
    
    [String]
    [Alias("Design")]
    $NewDesignScheme,

    [String]
    [Alias("Application")]
    $NewApplication
  )

#  Write-Host "Set PC called! Current config had CS: $($Config.ColorScheme.Name) DS: $($Config.Design.Name) App: $($Config.Design.Name)"

  if (-Not $NewColorScheme) {
#    Write-Host "No new CS provided. Using old configuration: $($Config.ColorScheme.Name)"
    $NewColorScheme = $Config.ColorScheme.Name
  } else {
#    Write-Host "New CS provided: $NewColorScheme"
  }

  if (-Not $NewDesignScheme) {
#    Write-Host "No new DS provided. Using old configuration: $($Config.Design.Name)"
    $NewDesignScheme = $Config.Design.Name
  } else {
#    Write-Host "New DS provided: $NewDesignScheme"
  }

  if (-Not $NewApplication) {
#    Write-Host "No new App provided. Using old configuration: $($Config.About.Name)"
    $NewApplication = $Config.About.Name
  } else {
#    Write-Host "New App provided: $NewApplication"
  }

#  Write-Host "Getting Config. File: $script:ConfigurationFileLocation CS: $NewColorScheme DS: $NewDesignScheme App: $NewApplication"

#  $C = Get-PUSH_Configuration $script:ConfigurationFileLocation -ColorScheme $NewColorScheme -Design $NewDesignScheme -Application $NewApplication
#  Write-Host "After getting new Push Config, the returned object looks like: CS: $($C.ColorScheme.Name), DS: $($C.Design.Name), App: $($C.About.Name)."
  return $(Get-PUSH_Configuration $script:ConfigurationFileLocation -ColorScheme $NewColorScheme -Design $NewDesignScheme -Application $NewApplication)
}