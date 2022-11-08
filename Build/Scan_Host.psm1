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
  Author:         Kyle Ketchell
  Creation Date:  May 29, 2022
.EXAMPLE
  Scan_Host.ps1 ETS_Test_Computer
#>

function Get-HardwareInfo {
  param([String]$Hostname)
  $Enclosure = Get-CimInstance Win32_SystemEnclosure -ComputerName $Hostname
  $System    = Get-CimInstance Win32_ComputerSystem -ComputerName $Hostname
  $Hardware  = @{
    Name          = $System.Name
    DNSName       = $System.DNSHostName
    OnDomain      = $System.PartOfDomain
    Domain        = $System.Domain
    Workgroup     = $System.Workgroup
    Manufacturer  = $System.Manufacturer
    Model         = $System.Model
    Serial        = $Enclosure.SerialNumber
    RAM           = [String]([Math]::Round($System.TotalPhysicalMemory / (1024 * 1024 * 1024))) + " GB"
  }
  $HardwareInformation = New-Object PSObject -Property $Hardware
  return $HardwareInformation
}

function Get-ProcessorInfo {
  param ([String]$Hostname)
  $Processor = Get-CimInstance Win32_Processor -ComputerName $Hostname
  $NameString = $Processor.Name
  $SpeedString = $Processor.MaxClockSpeed
  if ($Processor.Name -like "Intel*") {
    $NameString = $Processor.Name.SubString(0, $Processor.Name.IndexOf('@'))
    $SpeedString = $Processor.Name.Substring($Processor.Name.IndexOf('@')+2)
  } else {
    $NameString = $Processor.Name
    $SpeedString = [String]([Math]::Round($Processor.MaxClockSpeed/1000, 1)) + "GHz"
  }
  $Info = @{
    Name              = $NameString
    Speed             = $SpeedString 
    Cores             = $Processor.NumberOfCores
    LogicalProcessors = $Processor.NumberOfLogicalProcessors
  }
  $ProcessorInformation = New-Object PSObject -Property $Info
  return $ProcessorInformation
}

function Get-SoftwareInfo {
  param([String]$Hostname)
  $OS = Get-CimInstance Win32_OperatingSystem -ComputerName $Hostname
  $CS = Get-CimInstance Win32_ComputerSystem -ComputerName $Hostname
  $Software = @{
    Caption       = $OS.Caption
    Version       = $OS.Version
    Time          = $OS.LocalDateTime
    BootTime      = $OS.LastBootUpTime
    Uptime        = $OS.LocalDateTime - $OS.LastBootUpTime
    InstallDate   = $OS.InstallDate
    RUser         = $OS.RegisteredUser
    ROrganization = $OS.Organization
    Users         = $CS.UserName
    FreeRAM       = [String]([Math]::Floor($OS.FreePhysicalMemory / (1024 * 1024))) + "MB"
  }
  $SoftwareInformation = New-Object PSObject -Property $Software
  return $SoftwareInformation
}

function Get-DiskInfo {
  param ( [String]$Hostname )
  #Holy Shit its tough as balls to correlate a physical disk to a logical disk.

<#I think there's something going wrong if there's only one disk in the computer...#>

  $LocalDisks = Get-WmiObject Win32_DiskDrive -ComputerName $Hostname | ForEach-Object {
    $disk = $_
    $partitions = "ASSOCIATORS OF " +
                  "{Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} " +
                  "WHERE AssocClass = Win32_DiskDriveToDiskPartition"
    Get-WmiObject -Query $partitions -ComputerName $Hostname | ForEach-Object {
      $partition = $_
      $drives = "ASSOCIATORS OF " +
                "{Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} " +
                "WHERE AssocClass = Win32_LogicalDiskToPartition"
      Get-WmiObject -Query $drives -ComputerName $Hostname | ForEach-Object {
        $logical = $_
        New-Object -Type PSCustomObject -Property @{
          Disk_DeviceID = $disk.DeviceID 
          Disk_Partitions = $disk.Partitions 
          Disk_Size = $disk.Size
          Disk_Model = $disk.Model
          Disk_Caption = $disk.Caption
          Disk_Serial = $disk.SerialNumber
          Disk_Description = $disk.Description
          Disk_Name = $disk.Name
          Partition_Index = $partition.Index
          Partition_Name = $partition.Name
          Partition_Caption = $partition.Caption
          Partition_Size = $partition.Size
          Partition_Offset = $partition.StartingOffset
          LD_DeviceID = $logical.DeviceID
          LD_Caption = $logical.Caption
          LD_Description = $logical.Description
          LD_Name = $logical.Name
          LD_FreeSpace = $logical.FreeSpace
          LD_Size = $logical.Size
          LD_FileSystem = $logical.FileSystem
          LD_VolumeName = $logical.VolumeName
          LD_VolumeSerialNumber = $logical.VolumeSerialNumber
        }
      }
    }
  }

  $DiskInformation = New-Object System.Collections.ArrayList
  $LocalDisks | ForEach-Object {
    $LocalDiskInformation = Get-PhysicalDisk -Model $_.Disk_Caption
    $Information = @{
      DeviceName    = $_.LD_DeviceID
      Description   = $_.LD_VolumeName
      TotalDiskSize = [String]([Math]::Floor($_.Disk_Size / (1024 * 1024 * 1024))) + " GB"
      PartitionSize = [String]([Math]::Round($_.Partition_Size / (1024 * 1024 * 1024))) + " GB"
      FreeSpace     = [String]([Math]::Floor($_.LD_FreeSpace / (1024 * 1024 * 1024))) + " GB"
      UsedSpace     = [String]([Math]::Floor($_.LD_Size / (1024 * 1024 * 1024) - $_.LD_FreeSpace / (1024 * 1024 * 1024))) + " GB"
      FileSystem    = $_.LD_FileSystem
      VolumeName    = $_.LD_VolumeName
      VolumeSerial  = $_.LD_VolumeSerialNumber
      DiskName      = $_.Disk_Name
      DiskModel     = $_.Disk_Model
      DiskSerial    = $_.Disk_Serial
      MediaType     = $LocalDiskInformation.MediaType
    }
    $DiskObject =  New-Object psobject -Property $Information 
    $DiskInformation.Add($DiskObject)
  }
  return $DiskInformation
}

function Get-InstalledSoftware { # Requires Admin to run!
  param([String]$Hostname)
  $InstalledStorePrograms = Get-CimInstance Win32_InstalledStoreProgram -ComputerName $Hostname
  $InstalledProducts = Get-CimInstance Win32_InstalledWin32Program -ComputerName $Hostname
  $InstalledSoftware = New-Object System.Collections.ArrayList
  $InstalledProducts | ForEach-Object {
    $Information = @{
      Name         = $_.Name
      Program_ID   = $_.ProgramId
      Vendor       = $_.Vendor
      Version      = $_.Version
      StoreProduct = $false 
    }
    $Info = New-Object PSObject -Property $Information
    $InstalledSoftware.Add($Info)
  }
  $InstalledStorePrograms | ForEach-Object {
    $Information = @{
      Name         = $_.Name
      Program_ID   = $_.ProgramId
      Vendor       = $_.Vendor
      Version      = $_.Version
      StoreProduct = $true 
    }
    $Info = New-Object PSObject -Property $Information
    $InstalledSoftware.Add($Info)
  }
  return $InstalledSoftware
} # Requires Admin to Run!

#$Software = Get-InstalledSoftware -ComputerName Alfred
#Software | Format-Table Name, Version, Vendor

<#function Get-UserInfo {
  param ( [String]$Hostname )
  #Holy Shit its tough as balls to correlate a logged on session to their domain account and username.

  $LoggedOnUsers = Get-WmiObject Win32_LogonSession | ForEach-Object {
    $Session = $_
    $Users = "ASSOCIATORS OF " +
                  "{Win32_LogonSession.LogonID='$($Session.LogonID)'} " +
                  "WHERE AssocClass = Win32_LoggedOnUser"
    Get-WmiObject -Query $Users | ForEach-Object {
      $User = $_
      $UserInfo = "ASSOCIATORS OF " +
                "{Win32_Account.Name='$($User.Name)'} " +
                "WHERE AssocClass = Win32_LoggedOnUser"
      Get-WmiObject -Query $UserInfo | ForEach-Object {
        $UI = $_
        New-Object -Type PSCustomObject -Property @{
          Disk_DeviceID = $disk.DeviceID 
          Disk_Partitions = $disk.Partitions 
          Disk_Size = $disk.Size
          Disk_Model = $disk.Model
          Disk_Caption = $disk.Caption
          Disk_Serial = $disk.SerialNumber
          Disk_Description = $disk.Description
          Disk_Name = $disk.Name
          Partition_Index = $partition.Index
          Partition_Name = $partition.Name
          Partition_Caption = $partition.Caption
          Partition_Size = $partition.Size
          Partition_Offset = $partition.StartingOffset
          LD_DeviceID = $logical.DeviceID
          LD_Caption = $logical.Caption
          LD_Description = $logical.Description
          LD_Name = $logical.Name
          LD_FreeSpace = $logical.FreeSpace
          LD_Size = $logical.Size
          LD_FileSystem = $logical.FileSystem
          LD_VolumeName = $logical.VolumeName
          LD_VolumeSerialNumber = $logical.VolumeSerialNumber
        }
      }
    }
  }

  $DiskInformation = New-Object System.Collections.ArrayList
  $LocalDisks | ForEach-Object {
    $LocalDiskInformation = Get-PhysicalDisk -Model $_.Disk_Caption
    $Information = @{
      DeviceName    = $_.LD_DeviceID
      Description   = $_.LD_VolumeName
      TotalDiskSize = [String]([Math]::Floor($_.Disk_Size / (1024 * 1024 * 1024))) + " GB"
      PartitionSize = [String]([Math]::Round($_.Partition_Size / (1024 * 1024 * 1024))) + " GB"
      FreeSpace     = [String]([Math]::Floor($_.LD_FreeSpace / (1024 * 1024 * 1024))) + " GB"
      UsedSpace     = [String]([Math]::Floor($_.LD_Size / (1024 * 1024 * 1024) - $_.LD_FreeSpace / (1024 * 1024 * 1024))) + " GB"
      FileSystem    = $_.LD_FileSystem
      VolumeName    = $_.LD_VolumeName
      VolumeSerial  = $_.LD_VolumeSerialNumber
      DiskName      = $_.Disk_Name
      DiskModel     = $_.Disk_Model
      DiskSerial    = $_.Disk_Serial
      MediaType     = $LocalDiskInformation.MediaType
    }
    $DiskObject =  New-Object psobject -Property $Information 
    $DiskInformation.Add($DiskObject)
  }
  return $DiskInformation
}#> # saved for v1.0.9 [Unruly Users]

<#
function Get-RunningProcesses {
  # saved for v1.0.7 [Pesky Processes]
}
#>


function Get-NetworkInfo {
  param ( [String]$Hostname )
  $NetworkAdapterConfiguration  = Get-CimInstance Win32_NetworkAdapterConfiguration -ComputerName $Hostname | Where-Object { $_.IPAddress } # get network adapters which actually have an IP
  $NetworkAdapter = Get-CimAssociatedInstance $NetworkAdapterConfiguration -ComputerName $Hostname

  $NetworkInformation = New-Object -Type PSCustomObject -Property @{
    Name = $NetworkAdapterConfiguration.Description
    DHCPEnabled = $NetworkAdapterConfiguration.DHCPEnabled
    DHCPLeaseExpires = $NetworkAdapterConfiguration.DHCPLeaseExpires
    DHCPLeaseObtained = $NetworkAdapterConfiguration.DHCPLeaseObtained
    DHCPServer = $NetworkAdapterConfiguration.DHCPServer
    DNSDomain = $NetworkAdapterConfiguration.DNSDomain
    DNSDomainSuffixSearchOrder = $NetworkAdapterConfiguration.DNSDomainSuffixSearchOrder
    DNSHostName = $NetworkAdapterConfiguration.DNSHostName
    FullDNSRegistrationEnabled = $NetworkAdapterConfiguration.FullDNSRegistrationEnabled
    IPAddress = $NetworkAdapterConfiguration.IPAddress
    IPEnabled = $NetworkAdapterConfiguration.IPEnabled
    DefaultIPGateway = $NetworkAdapterConfiguration.DefaultIPGateway
    IPSubnet = $NetworkAdapterConfiguration.IPSubnet
    MACAddress = $NetworkAdapterConfiguration.MACAddress
    ServiceName = $NetworkAdapterConfiguration.ServiceName
    Speed = [String](($NetworkAdapter.Speed / (1000 * 1000 * 1000))) + " GB"
    AdapterType = $NetworkAdapter.AdapterType
    UID = $NetworkAdapter.GUID
    Manufacturer = $NetworkAdapter.Manufacturer
    NetConnectionID = $NetworkAdapter.NetConnectionID
    NetEnabled = $NetworkAdapter.NetEnabled
    ProductName = $NetworkAdapter.ProductName
    TimeOfLastReset = $NetworkAdapter.TimeOfLastReset
  }

  return $NetworkInformation
}


#Export-ModuleMember -Function Get-HardwareInfo -Alias Get-HardwareInformation
#Export-ModuleMember -Function Get-ProcessorInfo -Alias Get-ProcessorInformation
#Export-ModuleMember -Function Get-SoftwareInfo -Alias Get-SoftwareInformation
#Export-ModuleMember -Function Get-InstalledSoftware -Alias Get-InstalledSoftwareInformation