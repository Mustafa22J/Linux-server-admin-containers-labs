# backup.ps1 - Backup paperless-ngx Podman project

$ErrorActionPreference = "Stop"

# Paths
$userHome   = $env:USERPROFILE
$paperless  = Join-Path $userHome "paperless"
$backupRoot = Join-Path $userHome "backup"

# Ensure backup root exists
if (-not (Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot | Out-Null
}

# Create timestamped backup folder
$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDest = Join-Path $backupRoot "paperless-$timestamp"

Write-Host "Stopping paperless containers..."
Set-Location $paperless
podman compose down

Write-Host "Backing up contents of $paperless to $backupDest ..."
New-Item -ItemType Directory -Path $backupDest | Out-Null

# Copy EVERYTHING from paperless directory
Copy-Item -Path "$paperless\*" -Destination $backupDest -Recurse -Force

Write-Host "Starting paperless containers..."
podman compose up -d

Write-Host "Backup complete. Backup stored in $backupDest"
