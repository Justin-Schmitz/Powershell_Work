#Logging Functions

function LogToFile ($LogFilePath, $LogFileName, $extra_Messages = ".")
{
$check_for_Folder_Path = Test-Path $LogFilePath\$LogFileName
if ($check_for_Folder_Path.Equals($false)){
    New-Item -Path $LogFilePath -ItemType Directory
    New-Item -Path $LogFilePath -Name $LogFileName -ItemType File
    }
$time_FOR_Logging = (Get-Date).ToString("G")
"$time_FOR_Logging " + "------> The $LogFileName Check was done and is Working as expected $extra_Messages" >> "$LogFilePath\$LogFileName"
}

function LogToFile_Broken ($LogFilePath, $LogFileName, $Service_to_check, $extra_Messages = ".")
{
    $check_for_Folder_Path = Test-Path $LogFilePath\$LogFileName
    if ($check_for_Folder_Path.Equals($false)){
    New-Item -Path $LogFilePath -ItemType Directory
    New-Item -Path $LogFilePath -Name $LogFileName -ItemType File
    }
    $time_FOR_Logging = (Get-Date).ToString("G")
    "$time_FOR_Logging " + "------> $Service_to_check is NOT working as God had intended $extra_Messages" >> "$LogFilePath\$LogFileName"
}