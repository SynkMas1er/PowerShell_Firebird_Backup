########################################################
# Name: PowerShell_Firebird_Backup.ps1                      
# Creator: Volodja                    
# CreationDate: 30.08.2022                              
# LastModified: 30.08.2022                               
# Version: 0.1
# GitHub: https://github.com/SynkMas1er/PowerShell_Firebird_Backup
# PSVersion tested: 5
#
#
#
# Description: Copies the DB file to the Destination
# Only Change Variables in Variables Section
# 
#
########################################################
#
# Variables

$DBFile = "C:\finger\XNS.FDB"         # What Files you want to backup
$Dest = "C:\temp\backup"              # Copy the File to this Location

$Days = "90"                          # How many days the last Backups you want to keep

$logPath = "C:\Backup.log"            # Path to log file
$LogfileName = "Log"                  # Log Name

$Servicename = "firebird"             # Name of service to stop

$Date = Get-Date -uformat "%d-%m-%Y"
