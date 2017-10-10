function getUserStatus($userIdUrl){
   try {        $userStatus = (Invoke-RestMethod -Method GET -Uri $userIdUrl -Headers $global:hdrs -ContentType 'application/json').firstName
    } catch {

        Write-Host "Failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$userIdUrl'" -ForegroundColor white -BackgroundColor red
        Write-Host "  FAILED to obtain userStatus.  Exiting." -ForegroundColor white -BackgroundColor red
        exit
    }
  if ($userStatus) {return "user"} else {return "service"}
}
