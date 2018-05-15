    # Welcome to the Symphony Bot Collection

    # This PowerShell bot is brought to you by Symphony's Solutions Architect Team
    # Based on the pioneering work in PowerShell by Patrick O'Brien
    # Guided by the expertise of our API guy Mike Scannell
    # Under the realm of our fearless leader Kevin Byrne

    # Author: JoAnne Mann
    # Date: 5.15.2018
    # Copyright Symphony Communications LLC 2017 All Rights Reserved
    # These scripts are distributed as-is and are meant to be a template for automating pod administration tasks.

    # This is a Windows PowerShell Script and it was tested on Powershell 5.1 which can be found here:
    #    https://www.microsoft.com/en-us/download/details.aspx?id=54616
    # You may also enjoy the Windows Powershell Ingtegrated Script Environment (ISE) described here:
    #    https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/ise/introducing-the-windows-powershell-ise
    # You must run "Set-ExecutionPolicy RemoteSigned" as described here:
    #    http://windowsitpro.com/powershell/running-powershell-scripts-easy-1-2-3
    # In version 1.51 of Symphony, only TLS v1.2 is supported.  This line forces .NET to use TLS v1.2:
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Modify the "Fill in these Variables" section below for your specific pod and environment

    #                                ,,                       
    #                                 ||                       
    #      _-_, '\\/\\ \\/\\/\\ -_-_  ||/\\  /'\\ \\/\\ '\\/\\ 
    #     ||_.   || ;' || || || || \\ || || || || || ||  || ;' 
    #      ~ ||  ||/   || || || || || || || || || || ||  ||/   
    #     ,-_-   |/    \\ \\ \\ ||-'  \\ |/ \\,/  \\ \\  |/    
    #           (               |/      _/              (      
    #            -_-            '                        -_- 


# Fill in these Variables

    $certificateFileAndPath =     "C:\mycerts\bot.user1.p12"
    $certificateFilePassword =    "changeit"

    $sessionAuthUrl =  "https://myprivatepod-api.symphony.com/sessionauth/v1/authenticate"
    $Url =  "https://myprivatepod.symphony.com"
    $podUrl = "https://myprivatepod.symphony.com/pod"

    # CSV file that contains list of usernames
    $UserNamesFile = "SymphonyAddUsers.csv"

    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #currently this only supports unauthenticating proxys 
    #$proxy = "http://myproxy:8888/"


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

Write-Host "*** Successfully received sessionAuthToken: $sessionAuthToken"

# Define Headers
$hdrs = @{}
$hdrs.Add("sessionToken",$sessionAuthToken)

# Open CSV file and read entries
Write-Host "Opening file $UserNamesFile"
$Names = import-csv "$UserNamesFile" -header email,firstName,lastName,username,displayName 
ForEach ($Name in $Names) {

  $email = $($Name.email)
  $firstName = $($Name.firstName)
  $lastName = $($Name.lastName)
  $username = $($Name.username)
  $displayName = $($Name.displayName)

  # Skip Comments in the csv file
  if ($email.StartsWith("#") -eq  "True" ) {
     Write-Host "Found a comment in csv file: $email.  Skipping."

     Continue;
  }


$DataList = @{}
$DataList.Add("emailAddress",$email)
$DataList.Add("firstName",$firstName)
$DataList.Add("lastName",$lastName)
$DataList.Add("userName",$userName)
$DataList.Add("displayName",$displayName)
$DataList.Add("accountType","NORMAL")
$UserAttributes = @{}
$UserAttributes.Add("userAttributes",$DataList)

$json = $UserAttributes | ConvertTo-Json
write-host "Adding user $userName JSON: $json"

# Create the user
  try {
        if ($proxy) {    $Result = Invoke-RestMethod -Body $json -Method POST -ContentType 'application/json' -Headers $hdrs  -Proxy $proxy -Uri "$podUrl/v2/admin/user/create"}
        else        {    $Result = Invoke-RestMethod -Body $json -Method POST -ContentType 'application/json' -Headers $hdrs -Uri "$podUrl/v2/admin/user/create"}

Write-Host "***** Successfully created user $email userName $userName.   Result: $Result"

  } catch {

    Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    Write-Host "Current endpoint: '$podUrl/v2/admin/user/create'" -ForegroundColor white -BackgroundColor red
Write-Host "Failed to Add $userName.  Things to check: make certain the email address and username in the csv file are unique."
  }

Start-Sleep -s 3
}

  Write-Host "Elapsed time: " (NEW-TIMESPAN –Start $beforeTime –End (Get-Date)) 
                              
exit

