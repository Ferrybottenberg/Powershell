#  This script can be used to import certificates Non as Secure way and auto (Un)bind certificate



function ImportCertPfxNonSecure()
{
    # import cert without secure pwd
   
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
    # Import cert with secure pwd

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
    # get cert thumprint from latests expiration date
       
    $cert = Get-ChildItem Cert:\LocalMachine\My  | Where-Object {$_.Issuer -notmatch 'Unite Application Manager'} | Select-Object -Last 1  #select cert with latest date       
    return $cert.Thumbprint

}



function GetBindings()
{
    # get all cert bindings
    
    try{

        return & netsh.exe http show ssl

    } catch {

        return "Could retrieve bindings.", $_.ScriptStackTrace
    }
    
}


function GetCertHash()
{
    # get cert hash from binded port

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
    # write to logfile


    return "$env:USERPROFILE\Downloads\CertificateLog_$(Get-Date -f yyyy-MM-dd_HHmmss).log"

}



function UnbindCert()
{
      # Delete ssl binding
      
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
  


################################################################


# call Log function
$log = logs 



# 1. (Optional) Import new cert
#$filepathcert = '<cert>.pfx'

## use this if you want to use a non secure pwd
#$pwd = '<pwd>'
#$cert = ImportCertPfxNonSecure $filepathcert $pwd | Out-File $log -Append

## use this if you want to use a secure pwd
#$cert = ImportCertPfxSecure $filepathcert | Out-File $log -Append




# 2. get thumbprint of the cert with latest expiration date
$thumbprint = GetCertThumbprint 


# 3. Get bindings and write to logfile
GetBindings | Out-File $log -Append



$array = @(443,29912,444)
# 4. unbind certificate
foreach($port in $array) {

    UnbindCert $port | Out-File $log -Append

}


# 5. Bind certificate
foreach($port in $array) {

    BindCert $port $thumbprint  | Out-File $log -Append

}

