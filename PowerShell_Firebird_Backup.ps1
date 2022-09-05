#=============================================================================
# Name: PowerShell_Firebird_Backup.ps1                      
# Creator: Volodja                    
# CreationDate: 30.08.2022                              
# LastModified: 05.09.2022                               
# Version: 0.21
# GitHub: https://github.com/SynkMas1er/PowerShell_Firebird_Backup
# PSVersion tested: 3
#
#
#
# Description: Stopping service and copies the DB file to the Destination
# Only Change Variables in Variables Section
# 
#
#=============================================================================
#

# Variables

$Days = "-90"                                                                                   # How many days you want to keep old files (negative param)                                                                                 

$Servicename = "FirebirdServerDefaultInstance","FirebirdGuardianDefaultInstance"                # Name of service to stop

$Date = Get-Date -uformat "%d.%m.%Y"                                                            # Current date for naming
$Time = Get-Date -uformat "%H:%M"                                                               # Time for logging

$LogfileName = "Backup_log.$Date.log"                                                           # Log Name
$LogPath = [Environment]::GetFolderPath("Desktop") + "\$LogfileName"                            # Path to log file

$DBFile = "C:\finger\XNS.FDB"                                                                   # What Files you want to backup
$Dest = "C:\temp\"                                                                              # Copy the File to this Location

$Filename = ""                                                                                  # leave empty

function Out-Logger ($text,$allow=0) {
    if ($allow -eq 1) {
        "-----------------------END-----------------------" | Out-File $LogPath -Append
    }                                                                                               
    else {
        $Date +" " + $Time + " - " + $text |  Out-File $LogPath -Append              
    }                                                                                              
}
  
Out-Logger "Starting backup"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Error running script: RUN AS ADMIN OR SYSTEM ACCOUNT!"
    Out-Logger "Error running script: RUN AS ADMIN OR SYSTEM ACCOUNT!"
    Out-Logger 1 1
    Exit
}

try {
    Out-Logger "Stopping services..."
    Stop-Service -Name $Servicename -ErrorAction Stop  
}
catch {
   Out-Logger "Error: $_" 
   Out-Logger 1 1
   Exit                                                                                                     # Exit if no services there
}

Start-Sleep -Seconds 3

if ((Get-Service $Servicename).Status -eq 'Running') {
    Start-Sleep -Seconds 10
    if ((Get-Service $Servicename).Status -eq 'Running') {
        Start-Sleep -Seconds 10
    }
}
    
if (Test-Path $DBFile) {
    try {
        if (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") { 
            Set-Alias Compressor "$env:ProgramFiles\7-Zip\7z.exe"
            Out-Logger "7Zip found trying to compress..."
            $Filename = "$Date.XNS.FDB.backup.7z"
            Compressor a -mx=9 $Dest$Date.XNS.FDB.backup.7z $DBFile | Out-Logger                            # 7Zip file
                if ($LastExitCode -gt 0) {
                    Out-Logger "Error: 7zip reported some error. Deleting empty 7z file..."
                    Remove-Item "$Dest$Date.XNS.FDB.backup.7z"
                }
                else {
                    Out-Logger "File: $Filename created."
                }
        }
        elseif (Test-Path "$env:ProgramFiles\WinRAR\winrar.exe") {
            Set-Alias Compressor "$env:ProgramFiles\WinRAR\winrar.exe"
            Out-Logger "7Zip not found trying to compress with WinRAR..."
            $Filename = "$Date.XNS.FDB.backup.rar"
            Compressor a -m5 -n -y $Dest$Date.XNS.FDB.backup.rar $DBFile | Out-Logger                       # Winrar if no 7zip on system
            if (-not (Test-Path $Dest$Filename)) {
                    Out-Logger "Error: WinRar reported some error."
            }
            else {
                Out-Logger "File: $Filename created."
            }
        }  
        else {
            Out-Logger "7Zip and WinRAR not found trying to copy as is..."
            $Filename = "$Date.XNS.FDB.backup"
            Copy-Item -Path $DBFile -Destination "$Dest$Date.XNS.FDB.backup" -ErrorAction Stop              # Copy if no archiver found
            Out-Logger "File: $Filename created."
        }
    }
    catch {
        Out-Logger "Error: $_"
    }
}
else {
    Out-Logger ("Error: File $DBFile not found")
}


try {
    Start-Service -Name $Servicename -ErrorAction Stop                                                      # Starting service
}
catch {
   Out-Logger "Error: $_" 
   Out-Logger "Trying one more time..."
   Start-Sleep -Seconds 10                                                                                  # Wait for error is gone
    try {
        Start-Service -Name $Servicename -ErrorAction Stop
    }
    catch {
        Out-Logger "Error: $_ Check your services" 
        Out-Logger 1 1
        Exit                                                                                                # Exit if no services there or errors
    }
}

foreach ($i in $Servicename) {
    if ((Get-Service $i).Status -eq 'Running') {                                                            # Check service running
        Out-Logger "Service $i is started ok" 
    }
}

if (Test-Path "$Dest$Filename") {                                                                           # Dele old files if backup created
    $ChDaysDel = (Get-Date).AddDays($Days)
    Out-Logger "Deleting all files created earlier than $ChDaysDel"
    Get-ChildItem -Path $Dest -Recurse | Where-Object {$_.CreationTime -LT $ChDaysDel} | RI -Recurse -Force
}
else {
    Out-Logger "Old files are not deleted due to missing new backup file"
}
Out-Logger 1 1