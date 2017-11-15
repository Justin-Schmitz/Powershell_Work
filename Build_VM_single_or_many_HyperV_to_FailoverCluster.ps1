########################################################################
# Virtual Machine builder for Hyper V and FailOver Cluster Manager
# : 
# Created with tender love by Justin
# 2 Dec 2016
########################################################################    
# Workings:
#    - You choose to build a single or multiple servers
#    - You choose the location of the sysprep Windows server image to use
#    - If you choose single server mode, you will be prompted for all input
#    - If you choose for many server mode, you will have to locate the .csv to use
#    - Basic .csv with the columns:
#    - VMName | Memory | VLAN | Esize | Fsize | CPU
#    - Memory is in MB, eg. 1GB will be 1024 in the above column for the CSV
# 
#######################################################################

Add-Type `
  -AssemblyName Microsoft.VisualBasic

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.filter = "VHDX (*.vhdx)| *.vhdx"
    $OpenFileDialog.ShowDialog() | Out-Null

$CSource = $OpenFileDialog.FileName

    #Finds cluster node with highest free memory
    $ComputerName = Get-ClusterNode
    $ComputerName = $ComputerName[0].Name
    $highestFreeMemory = (Get-WmiObject Win32_operatingSystem -ComputerName $ComputerName).FreePhysicalMemory
    foreach ($clusternode in Get-ClusterNode)
    {
      $clusternode.Name
      (Get-WmiObject Win32_operatingSystem `
        -ComputerName $clusternode.Name).FreePhysicalMemory
      if ((Get-WmiObject Win32_operatingSystem `
        -ComputerName $clusternode.Name).FreePhysicalMemory -gt $highestFreeMemory)
      {
        $highestFreeMemory = (Get-WmiObject Win32_operatingSystem `
          -ComputerName $clusternode.Name).FreePhysicalMemory
        $ComputerName =  $clusternode.Name
      }
    }

    #Finds volume with highest freespace
    $csvs = Get-ClusterSharedVolume
    $VMPath = $csvs[0] | Select-Object `
      -Property Name `
      -ExpandProperty SharedVolumeInfo
    $highestFreeSpace = $VMPath.Partition.FreeSpace
    $VMPath = $VMPath.FriendlyVolumeName
    foreach ($csv in $csvs)
    {
      $csvinfos = $csv | Select-Object `
      -Property Name `
      -ExpandProperty SharedVolumeInfo
      foreach ($csvinfo in $csvinfos)
      {
        if ($csvinfo.Partition.FreeSpace -gt $highestFreeSpace)
        {
            $highestFreeSpace = $csvinfo.Partition.FreeSpace
            $VMPath = $csvinfo.FriendlyVolumeName
        }
      }
    }

do {
  $oneormore = [Microsoft.VisualBasic.Interaction]::InputBox('Are you building 1 or MANY servers?', 'Please enter 1 or Many?', '1 or Many')
}
until(($oneormore -eq '1') -or ($oneormore -eq 'Many') -or ($oneormore -eq 'many' ))

if($oneormore -eq '1'){
  Import-Module fail*
  $text = 'PleaseFillMeUp'
    $VMName = [Microsoft.VisualBasic.Interaction]::InputBox('VM Name please', 'Please Give me a name Sir', $text)
    $Generation = '2'
    $Memory	= [Microsoft.VisualBasic.Interaction]::InputBox('RAM/Memory',"How much RAM do you want to give $VMName Sir?", $text)
    $VLAN	= [Microsoft.VisualBasic.Interaction]::InputBox('Network VLAN',"What VLAN do you want $VMName in Sir?", $text)
    $Esize = [Microsoft.VisualBasic.Interaction]::InputBox('E Drive Space','What size do you want the E / DATA drive Sir?', $text)
    $Fsize = [Microsoft.VisualBasic.Interaction]::InputBox('F Drive Space','What size do you want the F / Logs drive Sir?', $text)
    $CPU = [Microsoft.VisualBasic.Interaction]::InputBox('Processor Amount',"How many procs do you want to give $VMName Sir?", $text)
    $SwitchName = 'Trunk'
    $CPU = $CPU
    [int64]$StartupMemory = 1MB*($Memory)
    [int64]$MaxMemory = 1MB*($i.MaxMemory)
    [int64]$MinMemory = 1MB*($i.MinMemory)
    [int64]$ESize = 1GB*($Esize)
    [int64]$FSize = 1GB*($Fsize)
    $CDestination = $VMPath+"\"+$VMName
    $CPathPre = $CDestination+"\"+$OpenFileDialog.SafeFileName
    $CPathPost = $CDestination+"\"+$VMName+"_C.vhdx"
    $EPath = $CDestination+"\"+$VMName+"_E.vhdx"
    $FPath = $CDestination+"\"+$VMName+"_F.vhdx"
    $CName = $VMName+"_C.vhdx"
    New-VM `
      -Name "$VMName" `
      -ComputerName $ComputerName `
      -Path $VMPath  `
      -Generation $Generation `
      -SwitchName $SwitchName
    Set-VM `
      -Name "$VMName" `
      -ComputerName $ComputerName `
      -StaticMemory `
      -MemoryStartupBytes $StartupMemory `
      -ProcessorCount $CPU
    Set-VMNetworkAdapterVlan `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -Access `
      -VlanId $VLAN
    New-VHD `
      -ComputerName $ComputerName `
      -Fixed `
      -SizeBytes $ESize `
      -Path $EPath
    New-VHD `
      -ComputerName $ComputerName `
      -Fixed `
      -SizeBytes $FSize `
      -Path $FPath
    Copy-Item `
      -Path "$CSource" `
      -Destination $CDestination `
      -Force
    Rename-Item `
      -Path $CPathPre $CName `
      -Force
    Add-VMHardDiskDrive `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -Path $CPathPost `
      -ControllerType SCSI
    Add-VMHardDiskDrive `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -Path $EPath `
      -ControllerType SCSI
    Add-VMHardDiskDrive `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -Path $FPath `
      -ControllerType SCSI
    $firstBoot = Get-VMHardDiskDrive `
      -ComputerName $ComputerName `
      -ControllerType SCSI `
      -VMName "$VMName" `
      -ControllerNumber 0 `
      -ControllerLocation 0
    Set-VMFirmware `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -FirstBootDevice $firstBoot
    Add-ClusterVirtualMachineRole `
      -VirtualMachine "$VMName"
    Start-VM `
      -ComputerName $ComputerName `
      -Name "$VMName"
  }
elseif($oneormore -eq "Many" -or "many"){
  Import-Module failover*
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $CSV_OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $CSV_OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $CSV_OpenFileDialog.ShowDialog() | Out-Null

$userobjects = Import-Csv -Path $CSV_OpenFileDialog.FileName
  foreach($i in $userobjects)
  {
    #Finds cluster node with highest free memory
    $ComputerName = Get-ClusterNode
    $ComputerName = $ComputerName[0].Name
    $highestFreeMemory = (Get-WmiObject Win32_operatingSystem -ComputerName $ComputerName).FreePhysicalMemory
    foreach ($clusternode in Get-ClusterNode)
    {
      $clusternode.Name
      (Get-WmiObject Win32_operatingSystem `
        -ComputerName $clusternode.Name).FreePhysicalMemory
      if ((Get-WmiObject Win32_operatingSystem `
        -ComputerName $clusternode.Name).FreePhysicalMemory -gt $highestFreeMemory)
      {
        $highestFreeMemory = (Get-WmiObject Win32_operatingSystem `
          -ComputerName $clusternode.Name).FreePhysicalMemory
        $ComputerName =  $clusternode.Name
      }
    }

    #Finds volume with highest freespace
    $csvs = Get-ClusterSharedVolume
    $VMPath = $csvs[0] | Select-Object `
      -Property Name `
      -ExpandProperty SharedVolumeInfo
    $highestFreeSpace = $VMPath.Partition.FreeSpace
    $VMPath = $VMPath.FriendlyVolumeName
    foreach ($csv in $csvs)
    {
      $csvinfos = $csv | Select-Object `
      -Property Name `
      -ExpandProperty SharedVolumeInfo
      foreach ($csvinfo in $csvinfos)
      {
        if ($csvinfo.Partition.FreeSpace -gt $highestFreeSpace)
        {
            $highestFreeSpace = $csvinfo.Partition.FreeSpace
            $VMPath = $csvinfo.FriendlyVolumeName
        }
      }
    }
    $VMName = $i.VMName
    $Generation = 2

    $SwitchName = "Trunk"
    $CPU = $i.CPU
    [int64]$StartupMemory = 1MB*($i.Memory)
    $VLAN = $i.VLAN
    [int64]$ESize = 1GB*($i.Esize)
    [int64]$FSize = 1GB*($i.Fsize)
    $CDestination = $VMPath+"\"+$VMName
    $CPathPre = $CDestination+"\"+$OpenFileDialog.SafeFileName
    $CPathPost = $CDestination+"\"+$VMName+"_C.vhdx"
    $EPath = $CDestination+"\"+$VMName+"_E.vhdx"
    $FPath = $CDestination+"\"+$VMName+"_F.vhdx"
    $CName = $VMName+"_C.vhdx"
    New-VM `
      -Name "$VMName" `
      -ComputerName $ComputerName `
      -Path $VMPath  `
      -Generation $Generation `
      -SwitchName $SwitchName
    Set-VM `
      -Name "$VMName" `
      -ComputerName $ComputerName `
      -StaticMemory `
      -MemoryStartupBytes $StartupMemory `
      -ProcessorCount $CPU
    Set-VMNetworkAdapterVlan `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -Access `
      -VlanId $VLAN
    New-VHD `
      -ComputerName $ComputerName `
      -Fixed `
      -SizeBytes $ESize `
      -Path $EPath
    New-VHD `
      -ComputerName $ComputerName `
      -Fixed `
      -SizeBytes $FSize `
      -Path $FPath
    Copy-Item `
      -Path "$CSource" `
      -Destination $CDestination `
      -Force
    Rename-Item `
      -Path $CPathPre $CName `
      -Force
    Add-VMHardDiskDrive `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -Path $CPathPost `
      -ControllerType SCSI
    Add-VMHardDiskDrive `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -Path $EPath `
      -ControllerType SCSI
    Add-VMHardDiskDrive `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -Path $FPath `
      -ControllerType SCSI
    $firstBoot = Get-VMHardDiskDrive `
      -ComputerName $ComputerName `
      -ControllerType SCSI `
      -VMName "$VMName" `
      -ControllerNumber 0 `
      -ControllerLocation 0
    Set-VMFirmware `
      -ComputerName $ComputerName `
      -VMName "$VMName" `
      -FirstBootDevice $firstBoot
    Add-ClusterVirtualMachineRole `
      -VirtualMachine "$VMName"
    Start-VM `
      -ComputerName $ComputerName `
      -Name "$VMName"
  }
}

