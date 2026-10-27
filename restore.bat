@echo off
echo ===================================================
echo Restoring stock launcher...
echo ===================================================

adb shell pm enable com.google.android.tvlauncher >nul 2>&1
adb shell pm enable com.mitv.tvhome.atv >nul 2>&1
adb shell pm enable com.google.android.apps.tv.launcherx >nul 2>&1
adb shell pm enable com.google.android.tungsten.setupwraith >nul 2>&1

adb shell settings put secure enabled_accessibility_services "" >nul 2>&1
adb shell settings put secure accessibility_enabled 0 >nul 2>&1

adb shell cmd package set-home-activity --user 0 com.google.android.tvlauncher/.MainActivity >nul 2>&1
adb shell cmd package set-home-activity --user 0 com.google.android.apps.tv.launcherx/.MainActivity >nul 2>&1

adb shell input keyevent KEYCODE_HOME

echo.
echo [SUCCESS] Stock launcher restored.
