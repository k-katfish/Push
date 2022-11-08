param(
    [Parameter()][Switch]
    $d = $false,
    [Parameter()][Switch][Alias("nb")]
    $NotBeta = $false,
    [Parameter()][Alias("dir")][String]
    $Location = "C:\Users\$env:Username\Documents",
    [Parameter()][Alias("Configure")][String]
    $ConfigurationFile = "C:\Users\$env:Username\Documents",
    [Parameter()][String]
    $ColorScheme = "Dark",
    [Parameter()][String]
    $DesignScheme = "Original",
    [Parameter()][String]
    $Application = "PUSH_2.0"
)

Set-Location $Location

#== Setup Configuration File
Write-Host "Generating Configuration File $ConfigurationFile"
$ConfigurationXML = New-Object XML
$ConfigurationXML.Load($ConfigurationFile)

$Compile_Info = $ConfigurationXML.SelectSingleNode("//Compile_Date")
$Compile_Info.InnerText = Get-Date

$Compile_Info = $ConfigurationXML.SelectSingleNode("//Compile_User")
$Compile_Info.InnerText = $env:USERNAME

$ConfigurationXML.Save($ConfigurationFile)

Import-Module .\Build\Push_Config_Manager.psm1
Import-Module ps2exe

$C = Get-PUSH_Configuration $ConfigurationFile -ColorScheme $ColorScheme -Design $DesignScheme -Application "PUSH"
$SH = Get-PUSH_Configuration $ConfigurationFile -ColorScheme $ColorScheme -Design $DesignScheme -Application "Scan_Host"

Set-Location ".\Build"

switch ($Application) {
  "Push" {
    if ($d) {
      Write-Host "Compiling in debug mode"
      ps2exe ".\Push_2.0.ps1" ".\Push_2.0_DEBUG.exe" -verbose
    } elseif (-Not $NotBeta) {
      Write-Host "Compiling Beta Version"
      $File = ".\PUSH_2.0.ps1"
      $Find = '#$b=$true'
      $Replace = '$b=$true'
      (Get-Content $File).Replace($Find, $Replace) | Set-Content $File
      ps2exe ".\PUSH_2.0.ps1" "..\PUSH_2.0_BETA.exe" -iconFile $C.Design.Icon -title $C.About.Title -description $C.About.Description -company $C.About.Company -version $C.About.Version -noOutput -noConsole
      (Get-Content $File).Replace($Replace, $Find) | Set-Content $File

      $Find = '#$d=$true'
      $Replace = '$d=$true'
      (Get-Content $File).Replace($Find, $Replace) | Set-Content $File
      ps2exe ".\PUSH_2.0.ps1" ".\PUSH_2.0-BETA-d.exe" -iconFile $C.Design.Icon -title $C.About.Title -description $C.About.Description -company $C.About.Company -version $C.About.Version
      (Get-Content $File).Replace($Replace, $Find) | Set-Content $File
    } else {
      ps2exe ".\PUSH_2.0.ps1" "..\PUSH_2.0.exe" -iconFile $C.Design.Icon -title $C.About.Title -description $C.About.Description -company $C.About.Company -version $C.About.Version -noOutput -noConsole
      #$File = "S:\ENS\Push_2.0\Build\PUSH_2.0.ps1"
      #$Find = '#$d=$true'
      #$Replace = '$d=$true'
      #(Get-Content $File).Replace($Find, $Replace) | Set-Content $File
      #ps2exe "S:\ENS\Push_2.0\Build\PUSH_2.0.ps1" "S:\ENS\Push_2.0\Build\PUSH_2.0-d.exe" -noOutput -noConsole
      #(Get-Content $File).Replace($Replace, $Find) | Set-Content $File
    }
  }

  "Scan_Host" {
    ps2exe ".\Scan_Host.ps1" ".\Scan_Host.exe" -iconFile $SH.Design.Scan_Host_Icon -title $SH.About.Title -description $SH.About.Description -company $SH.About.Company -version $SH.About.Version -noOutput -noConsole
  }
}

Set-Location "..\"