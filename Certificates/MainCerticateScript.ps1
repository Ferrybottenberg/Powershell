<#

  Version : 0.2
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

    0.1 UPS and writelog
    0.2 added Ofelia
    

#>





##################### START SCRIPT #####################
# read with named params. can be both names and unnamed

# NOTE  THIS MUST BE THE FIRST LINE of CODE. Don't put code above this line!


param ( 
        [parameter (Mandatory)]$cert,
        [parameter (Mandatory)]$certpwd,
        [parameter (Mandatory)]$system
    )




##################### Import ###################

. $PSScriptRoot/00-write-log.ps1
. $PSScriptRoot/01-ups.ps1
. $PSScriptRoot/02-ofelia.ps1







##################### main Functions ##################### 


function ExtensionCheck()
{
    <#

    .SYNOPSIS
    Checks certificate extension and returns boolean true or write to console and exit script

    .PARAMETER $Cert
    certificate with extension
    
    #>


    param(
        [string]$cert
    )


    if($cert -notlike "*.pfx"){
    
            write-host "Invalid input or order. Certificate must be of the '.pfx' type`n"
            Write-host "Input order: Certificate(.PFX) / Password / System "
            exit

    } else {
    
        return $true

    }

}






##################### system ##################### 
# first step after starting script



if($system -eq "ups"){
    
    $check = ExtensionCheck $cert
    if($check-eq $true){ UnitePS $cert $certpwd }

   
} elseif($system -eq "ofelia"){
    
    $check = ExtensionCheck $cert
    $certfolder = "C:\ProgramData\Ofelia\" 
    if($check-eq $true){ Ofelia $certfolder $cert $certpwd }


} elseif($system -eq "smartsense"){
    
    Smartsense $cert $pwd

} else {
    
    write-host "No system found. Check system name!"
}




