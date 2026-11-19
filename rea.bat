@echo off
setlocal
set "NODE_EXE=C:\Program Files\nodejs\node.exe"
set "REA_SCRIPT=%~dp0node_modules\rea-agents\scripts\rea.mjs"

if not exist "%REA_SCRIPT%" (
    rem Fallback to npx cache if local node_modules not yet linked
    set "REA_SCRIPT=C:\Users\HANS\AppData\Local\npm-cache\_npx\9b9809298fe40d2c\node_modules\rea-agents\scripts\rea.mjs"
)

"%NODE_EXE%" "%REA_SCRIPT%" %*
