function getRoomName($roomUrl){
   try {        $roomName = (Invoke-RestMethod -Method GET -Uri $roomUrl -Headers $global:hdrs -ContentType 'application/json').roomAttributes.name
    } catch {

        Write-Host "Failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$roomUrl'" -ForegroundColor white -BackgroundColor red
        Write-Host "  FAILED to obtain Room Name.  Exiting." -ForegroundColor white -BackgroundColor red
    }
  return $roomName
}
