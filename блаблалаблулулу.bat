@echo off
chcp 65001 >nul
echo ---------------------------------------------------------------------------
echo [SYSTEM ENGINEER] ACTIVATING LOCAL SUPPRESSION MODE
echo Target: Temporary disable Windows Defender protections.
echo Condition: ADMINISTRATOR rights required. Tamper Protection is the main obstacle.
echo ---------------------------------------------------------------------------
echo.
pause

:: -- PHASE 1: ATTEMPT TO DISABLE TAMPER PROTECTION VIA POWERSHELL --
echo [PHASE 1] Attempting to disable Tamper Protection via preferred method...
echo.
powershell -Command "Set-MpPreference -DisableTamperProtection 1" 2>nul
if %errorlevel% EQU 0 (
    echo [SUCCESS] Tamper Protection disabled via PowerShell.
) else (
    echo [WARNING] Failed to disable Tamper Protection via PowerShell.
    echo This is expected if controlled by group policies or cloud protection.
    echo Proceeding to Phase 2 - forced intervention.
)
echo.

:: -- PHASE 2: FORCED REGISTRY AND SERVICE MANIPULATION --
echo [PHASE 2] Applying forced system configuration changes...
echo.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d "0" /f >nul 2>&1

net stop WinDefend >nul 2>&1
net stop wscsvc >nul 2>&1
sc config WinDefend start= disabled >nul 2>&1
sc config wscsvc start= disabled >nul 2>&1

takeown /f "C:\Program Files\Windows Defender" /r /d y >nul 2>&1
icacls "C:\Program Files\Windows Defender" /deny "ALL APPLICATION PACKAGES":RX /t >nul 2>&1
icacls "C:\Program Files\Windows Defender" /deny "SYSTEM":RX /t >nul 2>&1

echo [STATUS] Configurations applied. Verifying state...
echo.
timeout /t 2 /nobreak >nul

:: -- PHASE 3: VERIFICATION --
tasklist /fi "IMAGENAME eq MsMpEng.exe" | find "MsMpEng.exe" >nul
if %errorlevel% EQU 0 (
    echo [CRITICAL FAILURE] Core Defender process (MsMpEng.exe) is still running.
    echo Manual termination via Task Manager is required.
) else (
    echo [SUCCESS] Defender processes not found in memory.
)

echo.
echo ---------------------------------------------------------------------------
echo [ENGINEERING ANALYSIS COMPLETE]
echo 1. Windows Update or a reboot will likely reset these changes.
echo 2. Your system is now vulnerable. Act accordingly.
echo ---------------------------------------------------------------------------
pause