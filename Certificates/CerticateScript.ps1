<#

  This script can be used to import certificates Non as Secure way and auto (Un)bind certificate
  after import the new certificate the thumbprint of the certifacte with the latest expiration date will be used for binding.
  STS certificate is ignored.

#>



##################### START SCRIPT #####################

# read with named params. can be both names and unnamed:
# .\test.ps1 -cert cert.pfx -pwd 2134 -system ofelia
# .\test.ps1 cert.pfx 2134 ofelia

param( 
    [parameter (Mandatory)]$cert,
    [parameter (Mandatory)]$pwd,
    [parameter (Mandatory)]$system
    )

    

##################### Functions ##################### 


function ImportCertPfxNonSecure()
{
    <#

    .SYNOPSIS
    Import cert without secure pwd

    .PARAMETER
    PFX file location

    #>

   
    param(
        [string]$filepathcert,
        [string]$certpwd
    )


    try{

        Import-PfxCertificate  -FilePath $filepathcert -CertStoreLocation Cert:\LocalMachine\My -Password (ConvertTo-SecureString $certpwd -AsPlainText -Force)
        return

    } catch {

        return "Cannot import certificate: ", $_.ScriptStackTrace
        
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

         return "Cannot find unbinded certificates", $_.ScriptStackTrace

    }

}



function GetBindings()
{

    <#

    .SYNOPSIS
     Get all cert bindings
    
    #>    
    
    try{

        return & netsh.exe http show ssl

    } catch {

        return "Could retrieve bindings.", $_.ScriptStackTrace
    }
    
}


function GetCertHash()
{
    <#

    .SYNOPSIS
    get cert hash from binded port

    .PARAMETER
    port

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

        return "Did not find binding for port $port"

    }
}


function Logs()
{
     <#

    .SYNOPSIS
    Write outout to logfile
    
    #>


    return "$env:USERPROFILE\Downloads\CertificateLog_$(Get-Date -f yyyy-MM-dd_HHmmss).log"

}


function UnbindCert()
{
     <#

    .SYNOPSIS
    Unbind certificate from port

    .PARAMETER
    Port number

    #>
      
      param(
        [string]$port
      )
     
      try{

          & netsh.exe http delete ssl ipport=0.0.0.0:$port
          return "UnBind SSL Certificate port $port succesfully."

      } Catch {

        return "Cannot delete SSL Certificate binding for $port.",  $_.ScriptStackTrace

      }
}



function BindCert()
{
    <#

    .SYNOPSIS
    Bind certificate to port

    .PARAMETER
    Port

    .PARAMETER
    contains Thumbprint / certificate hash of newly bindend certificate

    #>

    param(
    [string]$port,
    [string]$certhash
    )

    $app_id = '{4dc3e181-e14b-4a21-b022-59fc669b0914}'
    
    try{

        if (-not (netsh http show sslcert | Where-Object { $_ -match "IP:port\s+: 0.0.0.0:$port" })) {

            & netsh.exe http add ssl ipport=0.0.0.0:$port certhash=$certhash appid=$app_id clientcertnegotiation=disable
            return "Bind SSL Certificate port $port succesfully."

        } else {

            return "Port $port is already in use in a certificate binding."

        }
  
    } catch {

        return "Cannot bind SSL Certificate for $port.",  $_.ScriptStackTrace

    }
}
  

function CompareCert()
{
    <#

    .SYNOPSIS
    Stores both thumbprints of the array position 0 and 1 into a variable.
    Stores both Expiration date of the array position 0 and 1 into a variable
    Stores current date into a variable
    Then compares both dates with the current date and the thumbprint of the timestamp that is most away from current date will be returned

    .PARAMETER
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
    
        return "Cannot Compare timestamps. there is only one certificate to compare",  $_.ScriptStackTrace
        
    }


} 



function DelCert()
{
    <#
    .SYNOPSIS
    Delete certificate based on thumbprint

    .PARAMETER
    Certficate Tumbprint 
    
    #>
    

    param(
    [string]$thumbprint
    )


    try{

        return (Get-ChildItem Cert:\LocalMachine\My\$thumbprint | Remove-Item)

    } catch {

        return "Cannot delete certificate: ", $_.ScriptStackTrace
    }
}


function CheckImportCert()
{
    <#

    .SYNOPSIS
    Checks the length of the parameter. If value is zero then the function exit the script.

    .PARAMETERS
    Thumbprint of the new imported certificate

    #>

    param(
        [string]$certificateinfo
    )

    if($certificateinfo.Length -eq '0'){

       return "Import Certificate failed. Exit script."
       Exit

    } else {
       
        return "Certificate Import succesfully"

    }

       
}


##################### function "system choice" ##################### 

function UnitePS()
{

    <##>

    param(
        [string]$certificateimport,
        [string]$password
    )
    
       
    # 1. Import new cert
    $result = ImportCertPfxNonSecure $certificateimport $password
    $result = $result.Thumbprint
    
    # import checken
    $continuecheck = CheckImportCert $result
    
    write-host "1" $continuecheck
    $continuecheck.gettype()

    if($continuecheck -like "*succesfully*"){
        
        write-host "2" $continuecheck

        # 2. Get thumbprint of the cert with latest expiration date
        #    returns all information of all isntalled certificates
        #    call comparecert and receive only the thumbprint with the latest expiration date
    
        $certinfo = GetAllCertInfo 
        $thumbprintnew = CompareCert $certinfo 
        write-host "thumbprint new: " $thumbprintnew




        # 3.  Get the certifcate hash from the current binded port 443
        $port = 443
        $thumbprintold= GetCertHash $port 
        write-host "thumbprint old: " $thumbprintold



        # 4. Get bindings and write to logfile
        GetBindings | Out-File $log -Append


        # 5 and 6. (Un)bind certificate
        $array = @(443,29912,444)
        foreach($port in $array) {

            UnbindCert $port | Out-File $log -Append
    
        }

        foreach($port in $array) {

            BindCert $port $thumbprintnew  | Out-File $log -Append
    
        }



        # 7. Get the new bindings and write to logfile
        GetBindings | Out-File $log -Append



        # 8. Delete unbinded certificate
        DelCert $thumbprintold | Out-File $log -Append
        write-host "Deleted certificate thumbprint" $thumbprintold
    }

}

function Ofelia()
{
    write-host "Hi Ofelia"
}


##################### Logs ##################### 

# call Log function
$log = logs




##################### system ##################### 

# first step after starting script
if($system -eq "ups"){
    UnitePS $cert $pwd 
} elseif($system -eq "ofelia"){
    Ofelia
} elseif($system -eq "smartsense"){
    Smartsense
} else {
    write-host "No system found!"
}






# write to logs
# write for Ofelia
# write for SS