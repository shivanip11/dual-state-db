param([string]$Target = 'D:\SEM3\dbms\dual-state-database-auditor')
$ErrorActionPreference = 'Stop'
$resolvedTarget = (Resolve-Path -LiteralPath $Target).Path
if (-not (Test-Path -LiteralPath (Join-Path $resolvedTarget 'app\merkle.py'))) { throw 'Target is not the expected project clone.' }
if ($resolvedTarget.TrimEnd('\') -eq $PSScriptRoot.TrimEnd('\')) { throw 'Run this script from the extracted package, not the destination.' }
$backupRoot = Join-Path $resolvedTarget ('upgrade-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$paths = @('demo','tests\test_receipts.py','evidence\unit-tests.txt','evidence\experiments.json','evidence\live-api.json','DEMO_GUIDE.md','submission')
foreach ($relative in $paths) {
 $sourcePath = Join-Path $PSScriptRoot $relative
 $targetPath = Join-Path $resolvedTarget $relative
 if (Test-Path -LiteralPath $targetPath) {
  $backupPath = Join-Path $backupRoot $relative
  New-Item -ItemType Directory -Path (Split-Path -Parent $backupPath) -Force | Out-Null
  Copy-Item -LiteralPath $targetPath -Destination $backupPath -Recurse -Force
 }
 New-Item -ItemType Directory -Path (Split-Path -Parent $targetPath) -Force | Out-Null
 if (Test-Path -LiteralPath $sourcePath -PathType Container) {
  New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
  Get-ChildItem -LiteralPath $sourcePath | Copy-Item -Destination $targetPath -Recurse -Force
 } else { Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force }
}
$readmePath = Join-Path $resolvedTarget 'README.md'
$readmeText = Get-Content -LiteralPath $readmePath -Raw
if (-not $readmeText.Contains('# Receipt reconciliation upgrade')) {
 New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
 Copy-Item -LiteralPath $readmePath -Destination (Join-Path $backupRoot 'README.md')
 $intro = @('# Receipt reconciliation upgrade','','See DEMO_GUIDE.md for the tested SQLite demo. Run python -m demo.server --port 18877 and open http://127.0.0.1:18877. Original pipeline instructions follow.','','') -join [Environment]::NewLine
 Set-Content -LiteralPath $readmePath -Value ($intro + $readmeText) -Encoding UTF8
}
$ignorePath = Join-Path $resolvedTarget '.gitignore'
$ignoreText = Get-Content -LiteralPath $ignorePath -Raw
if (-not $ignoreText.Contains('# Generated receipt laboratory data')) {
 Add-Content -LiteralPath $ignorePath -Value (@('','# Generated receipt laboratory data','*.sqlite','*.sqlite-journal','data/presentation-*/','upgrade-backups/') -join [Environment]::NewLine)
}
Write-Host 'Upgrade applied. Private configuration and original database data were preserved.'
Write-Host ('Open this folder in VS Code: ' + $resolvedTarget)
Write-Host 'From that folder run: .\.venv\Scripts\python.exe -m demo.server --port 18877'
