<#
.SYNOPSIS
    Script otomatis untuk mengunduh APK target latihan atau dari URL langsung.
.EXAMPLE
    .\download_apk.ps1 -Target uncrackable1
    .\download_apk.ps1 -Url "https://example.com/target.apk" -OutputFile "target.apk"
#>

param(
    [string]$Target = "uncrackable1",
    [string]$Url = "",
    [string]$OutputFile = ""
)

$KNOWN_TARGETS = @{
    "uncrackable1" = "https://raw.githubusercontent.com/OWASP/owasp-mastg/master/Crackmes/Android/Level_01/UnCrackable-Level1.apk"
    "uncrackable2" = "https://raw.githubusercontent.com/OWASP/owasp-mastg/master/Crackmes/Android/Level_02/UnCrackable-Level2.apk"
    "uncrackable3" = "https://raw.githubusercontent.com/OWASP/owasp-mastg/master/Crackmes/Android/Level_03/UnCrackable-Level3.apk"
}

if ($Url -ne "") {
    $downloadUrl = $Url
    if ($OutputFile -eq "") {
        $OutputFile = [System.IO.Path]::GetFileName($Url)
        if ($OutputFile -notlike "*.apk") { $OutputFile = "downloaded_app.apk" }
    }
} elseif ($KNOWN_TARGETS.ContainsKey($Target.ToLower())) {
    $downloadUrl = $KNOWN_TARGETS[$Target.ToLower()]
    if ($OutputFile -eq "") {
        $OutputFile = "$($Target.ToLower()).apk"
    }
} else {
    Write-Host "Target '$Target' tidak dikenali. Pilihan target siap pakai: uncrackable1, uncrackable2, uncrackable3" -ForegroundColor Yellow
    Write-Host "Atau gunakan parameter -Url <link_langsung_apk>" -ForegroundColor Yellow
    exit 1
}

$destPath = Join-Path $PSScriptRoot $OutputFile
Write-Host "[*] Mengunduh otomatis dari: $downloadUrl ..." -ForegroundColor Cyan
Write-Host "[*] Menyimpan ke: $destPath ..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destPath -UseBasicParsing
    Write-Host "[+] Berhasil mengunduh $OutputFile!" -ForegroundColor Green
    Write-Host "[+] Ukuran: $((Get-Item $destPath).Length) bytes" -ForegroundColor Green
} catch {
    Write-Host "[-] Gagal mengunduh: $($_.Exception.Message)" -ForegroundColor Red
}
