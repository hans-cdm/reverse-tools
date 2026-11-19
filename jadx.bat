@echo off
setlocal
set "JADX_EXE=%~dp0jadx\jadx-gui-1.5.7.exe"

if exist "%JADX_EXE%" (
    start "" "%JADX_EXE%" %*
) else (
    echo [!] File JADX tidak ditemukan di folder jadx.
)
