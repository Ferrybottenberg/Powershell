#  This script can be used to import certificates Non as Secure way and auto (Un)bind certificate
#  after import the new certificate the thumbprint of the certifacte with the latest expiration date will be used for binding.
#  STS certificate is ignored.



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

        return Import-PfxCertificate  -FilePath $filepathcert -CertStoreLocation Cert:\LocalMachine\My -Password (ConvertTo-SecureString $certpwd -AsPlainText -Force)

    } catch {

        return "Cannot import certificate: ", $_.ScriptStackTrace

    }

  
}


function ImportCertPfxSecure()
{
    <#

    .SYNOPSIS
    Import cert with secure pwd

    .PARAMETER
    PFX file location

    #>

     param(
        [string]$filepathcert
    )

    $certpwd = Get-Credential -UserName 'Enter password below' -Message 'Enter password below'
    $certpwd = $certpwd.Password

    try{

       return Import-PfxCertificate  -FilePath $filepathcert -CertStoreLocation Cert:\LocalMachine\My -Password $certpwd

    } catch {

       return "Cannot import certificate: ", $_.ScriptStackTrace
    }


}



function GetCertThumbprint()
{

    <#

    .SYNOPSIS
     Get and return certificate information

    .PARAMETER
    Argument for the select-object

    #>

    
    param(
        [string]$itime
    )

    try{
        switch($itime)
        {

           last{Get-ChildItem Cert:\LocalMachine\My  | Where-Object {$_.Issuer -notmatch 'Unite Application Manager'} | select-Object -Last 1}
           first{Get-ChildItem Cert:\LocalMachine\My  | Where-Object {$_.Issuer -notmatch 'Unite Application Manager'} | select-Object -First 1}
    
        }
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
  

function CompareItems()
{
    <#

    .SYNOPSIS
    compare two variables

    .PARAMETER
    item a

    .PARAMETER
    item b

    
    #>

    param(
        [string]$itemA,
        [string]$itemB
    )

    write-host "A" $itemA
    write-host "B" $itemB

    try{
       
        if($itemA -eq $itemB){

            return "Compared Item A with Item B, both are the same."

        } else {

            return $itemB

        }
    } catch {
    
        return "Cannot Compare:",  $_.ScriptStackTrace
        
    }
}


function DelCert()
{

    param(
    [string]$thumbprint
    )

    try{

        return (Get-ChildItem Cert:\LocalMachine\My\$thumbprint | Remove-Item)

    } catch {

        return "Cannot delete certificate: ", $_.ScriptStackTrace
    }
}



################################################################


# call Log function
$log = logs 



# read from ?? klaas-bram


# 1. Import new cert
#$filepathcert = 'c:\1Node6.envac.local8-9.pfx'

## use this if you want to use a non secure pwd
#$pwd = '<pwd>'
#$cert = ImportCertPfxNonSecure $filepathcert $pwd | Out-File $log -Append

## use this if you want to use a secure pwd
#$cert = ImportCertPfxSecure $filepathcert | Out-File $log -Append




# 2. Get thumbprint of the cert with latest expiration date
$ilast = 'last'
$thumbprintlast = GetCertThumbprint $ilast    # returns all parameters of certificate
$thumbprintlast = $thumbprintlast.Thumbprint  # get only the thumbprint





# 3. Get bindings and write to logfile
GetBindings | Out-File $log -Append



$array = @(443,29912,444)
# 4. Unbind certificate
foreach($port in $array) {

    UnbindCert $port | Out-File $log -Append
    
}



# 5. Bind certificate
foreach($port in $array) {

    BindCert $port $thumbprintlast  | Out-File $log -Append
    
}


# 6. Get bindings and write to logfile
#GetBindings 



# 7. Delete Unbinded certificate
# Get thumbprint and expiration date of the cert with first expiration date
$ifirst = 'first'
$thumbprintfirst = GetCertThumbprint $ifirst    # returns all parameters of certificate
$thumbprintfirst = $thumbprintfirst.Thumbprint  # get only the thumbprint

# Get certifcate hash from binded port
$port = 443
$bindedcerthash = GetCertHash $port 

#call function to compare binded and unbinded thumbprint
write-host "last " $thumbprintlast
write-host "First " $thumbprintfirst
write-host "bindend " $bindedcerthash
write-host "unbinded " $thumbprintfirst

#call compareitems and return unbinded thumbprint and use as arg into function delcert
$cert = CompareItems $bindedcerthash $thumbprintfirst
write-host $cert


if($cert -gt 1 ){write-host " space"}






#? wat is parameter -last object = positionin array
# change how to get latest cert.. do it by expiration time and not -last first
# then fix nr 7

# write to logs
# read arg from start script  <script> arg1 <loc_of_pfx>   arg2 <ww>  arg3 < ofelia, ups, SS > and call the right functions using if statemnt
# make arg in start script mandatory