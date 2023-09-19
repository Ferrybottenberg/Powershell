<#

  Version : 0.1
  Date    : 19-9-2023


  This script can be used to import certificates (NonSecure) and auto (Un)bind old with new certificate.
  after import the new certificate the thumbprint of the certifacte with the latest expiration date will be used for binding and the old non used 
  certificate will be deleted. 
  the STS certificate will be ignored.


  Start the script with three arguments. All arguments are mandatory and will be used to import the right certificate at the right way.
  Start powershell ISE as "Administrator" and run one of the codes below.
  
  Start script example:  

            Format  >>    .\<scriptname>.ps1 -cert <path\to\certificate> -pwd <certificate\password> -system <UPS\Ofelia\USS>
            
                    >>    .\<scriptname>.ps1 -cert c:\certificate.pfx -pwd 1234 -system ups

                        or
            
                    >>    .\<scriptname>.ps1 c:\certificate.pfx 1234 ups



    NOTE: Script only works if a certificate is already installed. And Single node only
#>




##################### Release Notes ####################
<#

    0.1 First release With UPS
    
#>


##################### Functions ####################

function ImportCertPfxNonSecure()
{
    <#

    .SYNOPSIS
        Import certificate without secured pwd

    .PARAMETER $filepathcert
        PFX certificate with file location

    .PARAMETER $certpwd
        PFX certificate password

    #>

   
    param(
        [string]$filepathcert,
        [string]$certpwd
    )


    try{

        Import-PfxCertificate  -FilePath $filepathcert -CertStoreLocation Cert:\LocalMachine\My -Password (ConvertTo-SecureString $certpwd -AsPlainText -Force)
        return "Verbose:Import Certificate successful"

    } catch {

        return "Error:Cannot import certificate: ", $_.ScriptStackTrace
        
    }

}


function GetAllCertInfo()
{
    <#

    .SYNOPSIS
        Get and return certificate information

    #>


    try{
        
        return Get-ChildItem Cert:\LocalMachine\My  | Where-Object {$_.Issuer -notmatch 'Unite Application Manager'}

    } catch {
        
        return "Error:Cannot find unbinded certificates", $_.ScriptStackTrace

    }

}


function GetCertHash()
{
    <#

    .SYNOPSIS
        Get cert hash from binded port

    .PARAMETER $port
        contains port number

    #>


    param(
        [int]$port
    )


    $regex = 'Certificate Hash\s+:\s+([^:\s]+)'
    $arry = @()
    $arry = & netsh http show ssl ipport=0.0.0.0:$port
    $match = [regex]::Match($arry, $regex)
  
    if ($match.Success) {

        return $match.Groups[1].Value

    } else {

        return "Verbose:Did not find binding for port $port"

    }
}



function UnbindCert()
{
     <#

    .SYNOPSIS
        Unbind certificate from port

    .PARAMETER $port
        contains port number

    #>
      

      param(

        [string]$port
      
      )
     

      try{
        
        & netsh.exe http delete ssl ipport=0.0.0.0:$port | Out-Null
        return "Verbose:UnBind SSL Certificate of port $port succesfully."

      } Catch {
            
        return "Error:Cannot delete SSL Certificate binding for $port.",  $_.ScriptStackTrace

      }
}


function BindCert()
{
    <#

    .SYNOPSIS
        Bind certificate to port

    .PARAMETER $port
        contains port number

    .PARAMETER $certhash
        contains Thumbprint / certificate hash of newly bindend certificate

    #>


    param(

        [string]$port,
        [string]$certhash

    )


    $app_id = '{4dc3e181-e14b-4a21-b022-59fc669b0914}'
    try{

        if (-not (netsh http show sslcert | Where-Object { $_ -match "IP:port\s+: 0.0.0.0:$port" })) {

            & netsh.exe http add ssl ipport=0.0.0.0:$port certhash=$certhash appid=$app_id clientcertnegotiation=disable | Out-Null
            return "Verbose:Bind SSL Certificate port to $port successful."

        } else {

            return "Error:Port $port is already in use in a certificate binding."

        }
  
    } catch {

        return "Error:Cannot bind SSL Certificate for $port.",  $_.ScriptStackTrace

    }
}
  

function CompareCert()
{
    <#

    .SYNOPSIS
        Compares two timestamps and returns the thumbprint with the newest expiration date (notAfter)

    .DESCRIPTION
        Stores both thumbprints of the array position 0 and 1 into a variable.
        Stores both Expiration date of the array position 0 and 1 into a variable
        Stores current date into a variable
        Then compares both dates with the current date and the thumbprint of the timestamp that is most away from current date will be returned


    .PARAMETER $certinfo
        contains all certificate data and stored in an array 
    
    #>


    param(

        [array]$certinfo
    )
           
       
    try{
        $thumbprint1 = $certinfo[0].Thumbprint
        $thumbprint2 = $certinfo[1].Thumbprint
    
    
        $timestamp1 = $certinfo[0].NotAfter
        $timestamp2 = $certinfo[1].NotAfter         
   
        $currentTimestamp = Get-Date


        $timeDifference1 = New-TimeSpan -Start $currentTimestamp -End $timestamp1
        $timeDifference2 = New-TimeSpan -Start $currentTimestamp -End $timestamp2



        if ($timeDifference1 -gt $timeDifference2) {
   
            return $thumbprint1

         } else {

             return $thumbprint2
         }

    } catch {
    
        return "Error:Cannot Compare timestamps. there is only one certificate to compare",  $_.ScriptStackTrace
        
    }


} 


function DelCert()
{
    <#

    .SYNOPSIS
        Delete certificate based on thumbprint

    .PARAMETER $thumbprint
        Certficate Thumbprint 
    
    #>
    

    param(

        [string]$thumbprint

    )


    try{

        return (Get-ChildItem Cert:\LocalMachine\My\$thumbprint | Remove-Item)
        

    } catch {

        return "Error:Cannot delete certificate: ", $_.ScriptStackTrace
    }
}


function CheckImportCert()
{
    <#

    .SYNOPSIS
        Checks the length of the parameter. If value is zero then the function exit the script.

    .PARAMETER $certificateinfo
        Thumbprint of the new imported certificate

    #>
    

    param(
   
        [string]$certificateinfo

    )

    try {
        if($certificateinfo.Length -eq '0'){

           return "Error:Import Certificate failed. Exit script."
           Exit

        } else {
       
            return "Verbose:Import Certificate successful"

        }

    } catch {

        write-host "Error: Wrong certificate type. Exit script.", $_.ScriptStackTrace
        

    }
   
}


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


##################### function "system choice" ##################### 

function UnitePS()
{
    <#

    .SYNAPSIS
        This function handles certificate replacement for the UnitePS server.
    
    .DESCRIPTION
        various functions are called including import, control import, un- and binding and delete unused certificate. 
        All output will be saved in a logfile.

    .PARAMETER $certificateimport
        Imports the first arg. certificate 

    .PARAMETER $certificatepassword
        Imports the second arg. password

    #>


    param(

        [string]$certificateimport,
        [string]$certificatepassword
    )
    
       
    # 1. Import new cert
    $result = ImportCertPfxNonSecure $certificateimport $certificatepassword
    $result = $result.Thumbprint
    
    # 2. import checken
    $continuecheck = CheckImportCert $result
        
    if($continuecheck -like "*suc*"){
        
        
        # 3. Get thumbprint of the cert with latest expiration date
        #    returns all information of all isntalled certificates
        #    call comparecert and receive only the thumbprint with the latest expiration date
    
        $certinfo = GetAllCertInfo 
        $thumbprintnew = CompareCert $certinfo
        $msg = "Thumbprint new: ", $thumbprintnew
        writelog "Verbose" $msg
        Write-host $msg

        
        # 4.  Get the certifcate hash from the current binded port 443
        $port = 443
        $thumbprintold= GetCertHash $port 
        $msg = "Thumbprint old: ", $thumbprintold
        writelog "Verbose" $msg
        Write-host $msg


        
        # 4. Get bindings and write to logfile
        foreach($port in $array) {
            
            $bindings = & netsh http show sslcert ipport=0.0.0.0:$port
            writelog "Verbose" $bindings
                        
            foreach($line in $bindings) {
              
                write-host $line
            
            }

        }

        
        # 6 and 7. (Un)bind certificate
        $array = @(443,29912,444)
        
        foreach($port in $array) {

            $msg = UnbindCert $port
            $msg = SplitBeforeLog $msg
            writelog $msg[0] $msg[1]
            write-host $msg[1]

        }

        foreach($port in $array) {

            $msg = BindCert $port $thumbprintnew
            $msg = SplitBeforeLog $msg
            writelog $msg[0] $msg[1]
            write-host $msg[1]

        }

        
        # 8. Get the new bindings and write to logfile
        foreach($port in $array) {
            
            $bindings = & netsh http show sslcert ipport=0.0.0.0:$port

            $msg = SplitBeforeLog $bindings
            writelog "Verbose" $bindings
            
            foreach($line in $bindings) {
                
                write-host $line
            
            }


        }

        
        # 9. Delete unbinded certificate
        DelCert $thumbprintold | Out-File $log -Append
        
        $msg = "Deleted certificate with thumbprint: $thumbprintold"
        $msg = SplitBeforeLog $msg
        writelog $msg[0] $msg[1]
        write-host $msg[1]

                

    }

}


