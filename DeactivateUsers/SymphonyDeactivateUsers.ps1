    # Welcome to the Symphony Bot Collection

    # This PowerShell bot is brought to you by Symphony's Solutions Architect Team
    # Based on the pioneering work in PowerShell by Patrick O'Brien
    # Guided by the expertise of our API guy Mike Scannell
    # Under the realm of our fearless leader Kevin Byrne

    # Author: JoAnne Mann
    # Date: 1.16.2018
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
# This script will read a .csv file of user names and will deactivate those users.

# Fill in these Variables

    $certificateFileAndPath =     "C:\mycerts\bot.user1.p12"
    $certificateFilePassword =    "changeit"

    $sessionAuthUrl =  "https://mysymphony-api.symphony.com/sessionauth/v1/authenticate"
    $podUrl =  "https://mysymphony.symphony.com"

    # CSV file that contains list of usernames
    $UserNamesFile = "SymphonyUserNames.csv"

    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #currently this only supports unauthenticating proxys 
    #$proxy = "http://myproxy:8888/"

    $outpoutPath =   "c:\temp\"


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
$DataList.Add("status","DISABLED")
$json = $DataList | ConvertTo-Json

# Deactivate each user
  try {
        if ($proxy) {    $Result = Invoke-RestMethod -Body $json -Method POST -ContentType 'application/json' -Headers $hdrs  -Proxy $proxy -Uri "$podUrl/pod/v1/admin/user/$id/status/update"}
        else        {    $Result = Invoke-RestMethod -Body $json -Method POST -ContentType 'application/json' -Headers $hdrs -Uri "$podUrl/pod/v1/admin/user/$id/status/update"}

Write-Host "***** Successfully deactivated user $UserName ID $id.   Result: $Result"

  } catch {

    Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    Write-Host "Current endpoint: '$podUrl/pod/v1/admin/user/$id/update/status'" -ForegroundColor white -BackgroundColor red
Write-Host "Failed to deactivate $UserName ID $id "
  }

Start-Sleep -s 3
}

  Write-Host "Elapsed time: " (NEW-TIMESPAN –Start $beforeTime –End (Get-Date)) 
                              
exit

