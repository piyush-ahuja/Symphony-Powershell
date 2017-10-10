function getStreamID ($datafeedUrl,$global:hdrs) {
   try {        $streamID = (Invoke-RestMethod -Method POST -Uri $datafeedUrl -Headers $global:hdrs -ContentType 'application/json').id
    } catch {

        Write-Host "Failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to create datafeed  endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$datafeedUrl'" -ForegroundColor white -BackgroundColor red
        Write-Host "  FAILED to obtain datafeedID.  Exiting." -ForegroundColor white -BackgroundColor red
        exit
    }
  return $streamID
}
