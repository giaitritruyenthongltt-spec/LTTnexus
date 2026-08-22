# Dong goi + phat hanh mot ban Windows cua LTT Nexus.
#
# Lam ba viec ma truoc day phai lam tay va de sot:
#   1. dong goi zip (ban chay-khong-cai) + file cai MOT-FILE (tu giai nen)
#   2. tinh SHA-256 cho ca hai
#   3. dat vao data/nexus_dist tren may chu + cap nhat nexus_versions.json
#
# Chay SAU khi da build xong (xem BUILD_WINDOWS.md).
#
#   powershell -ExecutionPolicy Bypass -File phat-hanh-windows.ps1 -Version 1.2.0
#
# KHONG bao gio ghi de mot ban da phat hanh: ten file co version, va bien
# Cloudflare cache `immutable`. Ghi de thi nguoi tai sau van nhan ban cu.
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$Repo = 'D:\LTTnexus',
    [string]$DataDir = 'C:\LTTPlatform\data',
    [switch]$SkipPack   # bo qua buoc dong goi, chi phat hanh file da co
)

$ErrorActionPreference = 'Stop'
$rel  = Join-Path $Repo 'flutter\build\windows\x64\runner\Release'
$dist = Join-Path $Repo 'dist'
$zip  = Join-Path $dist "LTTNexus-$Version-win-x64.zip"
$setup = Join-Path $dist "LTTNexus-$Version-win-x64-setup.exe"

if (-not (Test-Path (Join-Path $rel 'LTTNexus.exe'))) {
    throw "Chua build: khong thay $rel\LTTNexus.exe"
}
New-Item -ItemType Directory -Force $dist | Out-Null

if (-not $SkipPack) {
    Write-Host '== 1/4: dong goi zip ==' -ForegroundColor Cyan
    if (Test-Path $zip) { Remove-Item $zip }
    Compress-Archive -Path (Join-Path $rel '*') -DestinationPath $zip -CompressionLevel Optimal

    Write-Host '== 2/4: dong goi file cai mot-file ==' -ForegroundColor Cyan
    Push-Location (Join-Path $Repo 'libs\portable')
    try {
        python generate.py -f "$rel\" -o . -e "$rel\LTTNexus.exe" | Out-Null
        cargo build --release | Out-Null
        $packed = Join-Path $Repo 'target\release\rustdesk-portable-packer.exe'
        if (-not (Test-Path $packed)) { throw 'khong thay rustdesk-portable-packer.exe' }
        Copy-Item $packed $setup -Force
    } finally { Pop-Location }
}

Write-Host '== 3/4: dat file vao may chu ==' -ForegroundColor Cyan
$distDir = Join-Path $DataDir 'nexus_dist'
New-Item -ItemType Directory -Force $distDir | Out-Null
Copy-Item $zip   $distDir -Force
Copy-Item $setup $distDir -Force

$zipHash   = (Get-FileHash (Join-Path $distDir (Split-Path $zip -Leaf))   -Algorithm SHA256).Hash.ToLower()
$setupHash = (Get-FileHash (Join-Path $distDir (Split-Path $setup -Leaf)) -Algorithm SHA256).Hash.ToLower()
$zipSize   = (Get-Item (Join-Path $distDir (Split-Path $zip -Leaf))).Length
$setupSize = (Get-Item (Join-Path $distDir (Split-Path $setup -Leaf))).Length

Write-Host '== 4/4: cap nhat ban ke phien ban ==' -ForegroundColor Cyan
$manifestPath = Join-Path $DataDir 'nexus_versions.json'
# DOC bang UTF-8 TUONG MINH. `Get-Content -Raw` cua PowerShell 5.1 doc theo
# bang ma ANSI, nen chu tieng Viet co dau trong `notes` se bi nat ngay o lan
# phat hanh KE TIEP - va nat mot cach im lang, vi script van chay xong.
$m = [IO.File]::ReadAllText($manifestPath, [Text.UTF8Encoding]::new($false)) | ConvertFrom-Json
$m.version = $Version
$w = $m.platforms.windows
$w.available    = $true
$w.url          = "/nexus/dl/LTTNexus-$Version-win-x64.zip"
$w.sha256       = $zipHash
$w.size         = $zipSize
$w | Add-Member -NotePropertyName setup_url    -NotePropertyValue "/nexus/dl/LTTNexus-$Version-win-x64-setup.exe" -Force
$w | Add-Member -NotePropertyName setup_sha256 -NotePropertyValue $setupHash -Force
$w | Add-Member -NotePropertyName setup_size   -NotePropertyValue $setupSize -Force

# UTF-8 KHONG BOM - quy tac bat buoc so 1 cua du an (json.load vo neu co BOM)
$json = ($m | ConvertTo-Json -Depth 10)
[IO.File]::WriteAllText($manifestPath, $json + "`n", (New-Object Text.UTF8Encoding($false)))

Write-Host ''
Write-Host "Da phat hanh $Version" -ForegroundColor Green
Write-Host ("  zip   : {0,7:N1} MB  {1}" -f ($zipSize/1MB), $zipHash)
Write-Host ("  setup : {0,7:N1} MB  {1}" -f ($setupSize/1MB), $setupHash)
Write-Host ''
Write-Host 'Kiem tra:  https://app.lttstudios.com/nexus/version.json'
