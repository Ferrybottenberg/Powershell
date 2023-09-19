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
   $fileExist = writelog "Verbose" "Something to log"
#>




function SplitBeforeLog()
{
    <#
    .SYNOPSIS
    Split string into array
        
    .DESCRIPTION
    Split message that contains msg level and msg. and return both. 
    
    .PARAMETERS $Log
    Message with Level


    #>
    

    param (
        [array]$log
    )


    $log = $log.Split(":")
    $msglevel = $log[0]
    $msg = $log[1]

    return $msglevel, $msg


}






function writelog()
{

    
    param(
        [string]$sType,
        [string]$sLog
    )

    
    #if (-not(Test-Path -Path $env:LOG_FILE))
    if ($Null -eq $env:LOG_FILE -or -not(Test-Path -Path $env:LOG_FILE) ) 
    {
        if ('' -ne $MyInvocation.PSScriptRoot)
        {
            $folder = Resolve-Path "./" # C:\Users\Administrator
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
    

    
    $log = "$( Get-Date ); - $sLog"
    switch ($sType)
    {
        Verbose
        {
            Add-Content -Path $fLogname -Value "[V] - $log"
            #write-verbose -Message $log
        }
        Warning
        {
            Add-Content -Path $fLogname -Value "[W] - $log"
            #write-warning -Message $log
        }
        Error
        {
            Add-Content -Path $fLogname -Value "[E] - $log"
            #write-error -Message $log
        }
        Default
        {
            Add-Content -Path $fLogname -Value "[I] - $log"
            #write-output $log
        }
    }
}


#$ENV:LOG_FILE = ''
#writelog "Verbose" "hallo"
