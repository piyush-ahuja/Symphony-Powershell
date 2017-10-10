function getUserName($userIdUrl){
   try {        $userName = (Invoke-RestMethod -Method GET -Uri $userIdUrl -Headers $global:hdrs -ContentType 'application/json').displayName
    } catch {

        Write-Host "Failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$userIdUrl'" -ForegroundColor white -BackgroundColor red
        Write-Host "  FAILED to obtain datafeedID.  Exiting." -ForegroundColor white -BackgroundColor red
        exit
    }
  return $userName
}
