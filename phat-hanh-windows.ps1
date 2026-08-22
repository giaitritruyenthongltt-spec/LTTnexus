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
# TEN FILE PHAI KET THUC BANG "install.exe" - day la mot rang buoc THAT, khong
# phai quy uoc dat ten. `libs/portable/src/main.rs`:
#     let click_setup = args.is_empty() && arg_exe.ends_with("install.exe");
#     if click_setup { args = vec!["--install"]; }
# Dat ten khac (vd "-setup.exe") thi bam dup CHI CHAY BAN TAM trong %LOCALAPPDATA%
# chu KHONG cai - va no chay binh thuong nen khong ai biet la da khong cai.
# Da dinh loi nay: ban 1.2.0/1.3.0 phat hanh voi ten "-setup.exe".
$setupTen = "LTTNexus-$Version-win-x64-install.exe"
$setup = Join-Path $dist $setupTen

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
# DAN XUAT tu ten file da chep len may chu. Truoc day day la mot chuoi viet
# cung THU HAI, doc lap voi $setup - doi mot cho ma quen cho kia thi ban ke
# tro vao file khong ton tai, va no hong o phia NGUOI DUNG chu khong hong luc
# phat hanh, nen khong ai thay. Da dinh dung loi nay o 1.4.0.
$w | Add-Member -NotePropertyName setup_url    -NotePropertyValue "/nexus/dl/$setupTen" -Force
$w | Add-Member -NotePropertyName setup_sha256 -NotePropertyValue $setupHash -Force
$w | Add-Member -NotePropertyName setup_size   -NotePropertyValue $setupSize -Force

# UTF-8 KHONG BOM - quy tac bat buoc so 1 cua du an (json.load vo neu co BOM)
$json = ($m | ConvertTo-Json -Depth 10)
[IO.File]::WriteAllText($manifestPath, $json + "`n", (New-Object Text.UTF8Encoding($false)))

# Kiem SAU KHI ghi: doc lai chinh ban ke vua ghi, doi chieu voi file tren dia.
# Chot chan phai kiem KET QUA, khong kiem bien vua gan - ban truoc kiem
# `$setup.EndsWith("install.exe")` ngay sau khi gan $setup ket thuc bang do, tuc
# la mot cau hoi luon dung, khong bao gio no duoc.
$kiem = [IO.File]::ReadAllText($manifestPath, [Text.UTF8Encoding]::new($false)) | ConvertFrom-Json
$urlCai = $kiem.platforms.windows.setup_url
if (-not $urlCai.ToLower().EndsWith("install.exe")) {
    throw "Ban ke tro toi '$urlCai' - ten PHAI ket thuc bang install.exe, neu khong bam dup se khong cai"
}
$fileCai = Join-Path $distDir (Split-Path $urlCai -Leaf)
if (-not (Test-Path $fileCai)) {
    throw "Ban ke tro toi '$urlCai' nhung khong co file do trong $distDir"
}

Write-Host ''
Write-Host "Da phat hanh $Version" -ForegroundColor Green
Write-Host ("  zip   : {0,7:N1} MB  {1}" -f ($zipSize/1MB), $zipHash)
Write-Host ("  setup : {0,7:N1} MB  {1}" -f ($setupSize/1MB), $setupHash)
Write-Host ''
Write-Host 'Kiem tra:  https://app.lttstudios.com/nexus/version.json'
