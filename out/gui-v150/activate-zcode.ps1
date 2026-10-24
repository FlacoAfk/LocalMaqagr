$p = Get-Process ZCode | Where-Object { $_.MainWindowTitle } | Select-Object -First 1
if ($p) {
  $r = (New-Object -ComObject WScript.Shell).AppActivate($p.Id)
  Write-Output ("activated=" + $r + " pid=" + $p.Id + " title=" + $p.MainWindowTitle)
} else {
  Write-Output "no ZCode window with MainWindowTitle found"
}
