# Creatated by Awitac 
# Changes                                                         ES/SA 2021-06-18 
###################################################################################
# 
# NOTE: Erlang needs to be installed first
#
# Script will change the default value of the erlang cookie in 
# "c:\windows\system32\config\systemprofile\.erlang.cookie" 
# to GEOQMMYBBKPAHKDIKYVB.
# 
# After changing the value in the system profile folder the script will do 
# the same for the current logged in user erlang cookie 
# 
# Step 2
# Copy modified erlang cookie to Document foler
#
##################################################################################
#
# Set Erlang Cookie in "windows\system32\config\systemprofile"
$erlangcookiefile  = "c:\windows\system32\config\systemprofile\.erlang.cookie"
$erlangcookievalue = "GEOQMMYBBKPAHKDIKYVB"
Set-Content -Path $erlangcookiefile -Value $erlangcookievalue -Force
#
#
# Set Erlang Cookie for "CURENT USER"
$erlangcookiefile  = "$ENV:UserProfile\.erlang.cookie"
$erlangcookievalue = "GEOQMMYBBKPAHKDIKYVB"
Set-Content -Path $erlangcookiefile -Value $erlangcookievalue -Force 
#
#
# Save Erlang Cookie in Documents folder
$file = "$ENV:UserProfile\Documents\.erlang.cookie"
if (-not(Test-Path -Path $file -PathType Leaf)) {
     try {
         $null = Copy-Item "c:\windows\system32\config\systemprofile\.erlang.cookie" -destination $ENV:UserProfile\Documents
         Write-Host "The file [$file] has been created."
     }
     catch {
         throw $_.Exception.Message
     }
 }
