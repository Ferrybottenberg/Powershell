<#
 .Synopsis
  Check if resource exist on http server

 .Desciption
  Log default to logs/default.log relatief to folder where powershell script is that is calling this function
  With $env:LOG_FILE you can change to your one desire.

 .Parameter sType
  One of ("Verbose", "Warning", "Error", "Default")

 .Parameter sLog
  The string to log to file

 .Example
   $fileExist = writelog "Verboase" "Something to log"
#>


function writelog()
{

    
    param(
        [string]$sType,
        [string]$sLog
    )

    if (-not(Test-Path -Path $env:LOG_FILE))
    {
        if ('' -ne $MyInvocation.PSScriptRoot)
        {
            $folder = Resolve-Path "./Documents" # C:\Users\Administrator
            write-host $folder
            New-Item  -Path "$folder/logs" -ItemType Directory
            
            $env:LOG_FILE =  "$folder/logs/default.log"
        } 
        else
        {
            $env:LOG_FILE = "$( $MyInvocation.PSScriptRoot )/logs/default.log"
        }
    }


    $fLogname = "$ENV:LOG_FILE"
    if (-not(Test-Path -Path $env:LOG_FILE))
    {
        New-Item $fLogname
    }
    else
    {

    
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
}


writelog "verbose" "hallo"

