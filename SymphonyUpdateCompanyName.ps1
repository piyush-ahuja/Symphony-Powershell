    # Welcome to the Symphony Bot Collection

    # This PowerShell bot is brought to you by Symphony's Solutions Architect Team
    # Based on the pioneering work in PowerShell by Patrick O'Brien
    # Guided by the expertise of our API guy Mike Scannell
    # Under the realm of our fearless leader Kevin Byrne

    # Author: JoAnne Mann
    # Date: 3.27.2018
    # Copyright Symphony Communications LLC 2017 All Rights Reserved
    # These scripts are distributed as-is and are meant to be a template for automating pod administration tasks.

    # This is a Windows PowerShell Script and it was tested on Powershell 5.1 which can be found here:
    #    https://www.microsoft.com/en-us/download/details.aspx?id=54616
    # You may also enjoy the Windows Powershell Ingtegrated Script Environment (ISE) described here:
    #    https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/ise/introducing-the-windows-powershell-ise
    # You must run "Set-ExecutionPolicy RemoteSigned" as described here:
    #    http://windowsitpro.com/powershell/running-powershell-scripts-easy-1-2-3

    # Modify the "Fill in these Variables" section below for your specific pod and environment

    #                                ,,                       
    #                                 ||                       
    #      _-_, '\\/\\ \\/\\/\\ -_-_  ||/\\  /'\\ \\/\\ '\\/\\ 
    #     ||_.   || ;' || || || || \\ || || || || || ||  || ;' 
    #      ~ ||  ||/   || || || || || || || || || || ||  ||/   
    #     ,-_-   |/    \\ \\ \\ ||-'  \\ |/ \\,/  \\ \\  |/    
    #           (               |/      _/              (      
    #            -_-            '                        -_- 


# ---------------------------------------------------------------------------------------------------------
# This script will read a .csv file of user names and will change the company name for that user.
# Company name must be entered exactly and correctly below in the $companyName variable.
# This script cannot accommodate UTF8 characters at this time.
# No error checking is provided if the company name is mis-spelled - it must be entered exactly as it
# is in the pod.  Future release will display a list of valid company names. 

# Fill in these Variables

    $certificateFileAndPath =     "C:\mycerts\bot.user1.p12"
    $certificateFilePassword =    "changeit"

    $sessionAuthUrl =  "https://mypod-api.symphony.com/sessionauth/v1/authenticate"
    $podUrl =  "https://mypod.symphony.com"
    #$companyName = "Enter the Exact Company Name Here"

    # CSV file that contains list of usernames
    $UserNamesFile = "SymphonySupUserNames.csv"

    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #currently this only supports unauthenticating proxys 
    #$proxy = "http://myproxy:8888/"

    $outpoutPath =   "c:\temp\"

$OutputEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Script Body

Clear-Host
Write-Host
Write-Host
Write-Host
Write-Host
Write-Host
Write-Host
$beforeTime = Get-Date
Write-Host "Starting at " $beforeTime.ToLocalTime()

    # Get p12 certificate thumbprint

    try {
            $certificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $certificateObject.Import($certificateFileAndPath, $certificateFilePassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::
DefaultKeySet)
            #Write-Host $certificateObject.Thumbprint

    } catch {

        Write-Host "ERROR: Certificate read failed with error '$($_.Exception.InnerException)'" -ForegroundColor white -BackgroundColor red
        exit
    }



    # Get SessionAuth token

    try {
        $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -CertificateThumbprint $certificateObject.Thumbprint).token
    } catch {

        Write-Host "failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to sessionauth endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$sessionAuthUrl'" -ForegroundColor white -BackgroundColor red

        exit
    }

# Define Headers
$hdrs = @{}
$hdrs.Add("sessionToken",$sessionAuthToken)

# Open CSV file and read entries
Write-Host "Opening file $UserNamesFile"
$Names = import-csv "$UserNamesFile" -header UserName 
ForEach ($Name in $Names) {

  $UserName = $($Name.UserName)
  Write-Host "Looking at $UserName for name $Name"
  # Skip Comments in the csv file
  if ($UserName.StartsWith("#") -eq  "True" ) {
     Write-Host "Found a comment in csv file: $UserID.  Skipping."
     Continue;
  }

# Look up ID from UserName
  try {
        if ($proxy) {    $fullUserList = Invoke-RestMethod -Method GET -Headers $hdrs -Proxy $proxy -Uri "$podUrl/pod/v2/user?username=$UserName&local=true" }
        else        {    $fullUserList = Invoke-RestMethod -Method GET -Headers $hdrs -Uri "$podUrl/pod/v2/user?username=$username&local=true"} 


  } catch {

    Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    Write-Host "Current endpoint: '$podUrl/pod/v1/admin/user'" -ForegroundColor white -BackgroundColor red

  }

$id=$fullUserList.id

# Next if ID is empty
if ( !$id ) {
  Write-Host "UserID for $email is empty; no such user found OR user already deactivated.  Skipping."
  Continue
}


$DataList = @{}
#$DataList.Add("emailAddress",$Email)
#$DataList.Add("userName",$UserName)
#$DataList.Add("status","DISABLED")
$DataList.Add("companyName",$companyName)
$json = $DataList | ConvertTo-Json

Write-Host "New companyName: $companyName"
# Update each user with the new company name
  try {
        if ($proxy) {    $Result = Invoke-RestMethod -Body $json -Method POST -ContentType 'application/json' -Headers $hdrs  -Proxy $proxy -Uri "$podUrl/pod/v1/admin/user/$id/update"}
        else        {    $Result = Invoke-RestMethod -Body $json -Method POST -ContentType 'application/json' -Headers $hdrs -Uri "$podUrl/pod/v1/admin/user/$id/update"}

Write-Host "***** Successfully updated user $UserName ID $id to companyName $companyName."

  } catch {
$($_.message) -match ("Invalid companyName\*")
#$_ | ConvertTo-Json {}
    #Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    #Write-Host "Current endpoint: '$podUrl/pod/v1/admin/user/$id/update'" -ForegroundColor white -BackgroundColor red
#Write-Host "Failed to update $UserName ID $id to companyName $companyName.  Make certain company name is one of '$($_.Exception.message) OR $($_.Exception.ItemName) WHAT!!!!!  $_  ugh!!!!!  $($_.Exception.data) '"
Write-Host "Failed: $($_.Exception.Response)"
$_.Exception | Get-Member
  }

Start-Sleep -s 3
}

  Write-Host "Elapsed time: " (NEW-TIMESPAN –Start $beforeTime –End (Get-Date)) 
                              
exit

