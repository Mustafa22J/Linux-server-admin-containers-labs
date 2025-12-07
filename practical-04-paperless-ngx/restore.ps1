# restore.ps1 - Restore paperless-ngx Podman project from latest backup

$ErrorActionPreference = "Stop"

$userHome   = $env:USERPROFILE
$paperless  = Join-Path $userHome "paperless"
$backupRoot = Join-Path $userHome "backup"

if (-not (Test-Path $backupRoot)) {
    Write-Error "Backup folder '$backupRoot' does not exist."
    exit 1
}

# Get most recent backup folder
$latestBackup = Get-ChildItem $backupRoot -Directory |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latestBackup) {
    Write-Error "No backups found in '$backupRoot'."
    exit 1
}

Write-Host "Using latest backup: $($latestBackup.FullName)"

# Stop containers if compose file exists
if (Test-Path (Join-Path $paperless "docker-compose.yml") -or
    Test-Path (Join-Path $paperless "podman-compose.yml")) {

    Write-Host "Stopping paperless containers..."
    Set-Location $paperless
    podman compose down
}
else {
    Write-Host "Compose file not found in '$paperless'. Skipping 'podman compose down'."
}

# Ensure paperless directory exists
if (-not (Test-Path $paperless)) {
    New-Item -ItemType Directory -Path $paperless | Out-Null
}

Write-Host "Clearing current contents of $paperless ..."
Get-ChildItem $paperless -Force | Remove-Item -Recurse -Force

Write-Host "Restoring files from $($latestBackup.FullName) ..."
Copy-Item -Path "$($latestBackup.FullName)\*" -Destination $paperless -Recurse -Force

Write-Host "Starting paperless containers..."
Set-Location $paperless
podman compose up -d

Write-Host "Restore complete."
