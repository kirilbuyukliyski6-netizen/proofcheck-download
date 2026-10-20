# Sverify: install with one line in PowerShell, no admin rights needed:
#   irm https://raw.githubusercontent.com/kirilbuyukliyski6-netizen/sverify-download/main/install.ps1 | iex
# Downloads the latest installer and installs it for the current user only (Windows' own msiexec).
# Uses 'return', never 'exit': under iex, 'exit' would close the user's PowerShell window.
# Test hooks (CI only): PROOFCHECK_MSI = local installer to use, PROOFCHECK_NOSTART = do not open the app.
& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'                                  # makes the download much faster
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 } catch {}  # TLS 1.2 on older Windows 10
    $url = 'https://github.com/kirilbuyukliyski6-netizen/sverify-download/releases/latest/download/Sverify.msi'
    $dir = Join-Path $env:TEMP 'Sverify-install'
    New-Item -ItemType Directory -Force $dir | Out-Null
    $msi = Join-Path $dir 'Sverify.msi'
    try {
        Write-Host 'Sverify: сваляне (около 100 MB, може да отнеме минута)...'
        if ($env:PROOFCHECK_MSI) { Copy-Item $env:PROOFCHECK_MSI $msi -Force }
        else { Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing }
        Write-Host 'Sverify: инсталиране...'
        $p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qb- /norestart" -Wait -PassThru
        if ($p.ExitCode -ne 0) { Write-Host "Sverify: инсталирането не успя (код $($p.ExitCode))." -ForegroundColor Red; return }
    } catch {
        Write-Host "Sverify: грешка: $($_.Exception.Message)" -ForegroundColor Red
        return
    } finally {
        Remove-Item $msi -Force -ErrorAction SilentlyContinue
    }
    $exe = Join-Path $env:LOCALAPPDATA 'Programs\Sverify\Sverify.exe'
    if (-not (Test-Path $exe)) { Write-Host 'Sverify: програмата не е намерена след инсталирането.' -ForegroundColor Red; return }
    Write-Host 'Готово. Sverify е на работния плот и в менюто Старт.' -ForegroundColor Green
    if (-not $env:PROOFCHECK_NOSTART) { Start-Process $exe }
}
