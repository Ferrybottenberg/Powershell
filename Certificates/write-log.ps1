<#
 .Synopsis
  Check if resource exist on http server

 .Desciption
  import script into another ps1 script by doing:  . PSScriptRoot/write-log.ps1
  
  Log default to logs/default.log relatief to folder where powershell script is that is calling this function
  With $env:LOG_FILE you can change to your one desire.

 .Parameter sType
  One of ("Verbose", "Warning", "Error", "Default")

 .Parameter sLog
  The string to log to file

 .Example

   $fileExist = writelog "Verboase" "Something to log"
#>
function writelog
{
    param (
        [string]$sType,
        [string]$sLog
    )

    if ($null -eq $env:LOG_FILE)
    {
        if ('' -eq $MyInvocation.PSScriptRoot)
        {
            $folder = Resolve-Path "./"
            createDir "$folder/logs"
            $env:LOG_FILE =  "$folder/logs/default.log"
        }
        else
        {
            $env:LOG_FILE = "$( $MyInvocation.PSScriptRoot )/logs/default.log"
        }
    }

    $fLogname = "$ENV:LOG_FILE"
    createFile $fLogname
    $log = "$( Get-Date ); - $sLog"

    switch ($sType)
    {
        Verbose
        {
            Add-Content -Path $fLogname -Value "INFO - $log"
            write-verbose -Message $log
        }
        Warning
        {
            Add-Content -Path $fLogname -Value "WARNING - $log"
            write-warning -Message $log
        }
        Error
        {
            Add-Content -Path $fLogname -Value "ERROR - $log"
            write-error -Message $log
        }
        Default
        {
            Add-Content -Path $fLogname -Value "INFO - $log"
            write-output $log
        }
    }
}
