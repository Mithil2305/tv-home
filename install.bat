@echo off
echo ===================================================
echo Installing tv-home onto connected TV...
echo ===================================================

echo [1/6] Installing APK...
adb install -r "%~dp0launcher\build\tvhome.apk"
if errorlevel 1 (
    echo Installation failed. Is your TV connected via ADB?
    exit /b 1
)

echo [2/6] Granting permissions...
adb shell pm grant com.mihir.tvhome android.permission.ACCESS_FINE_LOCATION

echo [3/6] Setting tv-home as default launcher...
adb shell cmd package set-home-activity --user 0 com.mihir.tvhome/.MainActivity

echo [4/6] Disabling stock launcher and PatchWall...
adb shell pm disable-user --user 0 com.google.android.tvlauncher >nul 2>&1
adb shell pm disable-user --user 0 com.mitv.tvhome.atv >nul 2>&1
adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx >nul 2>&1
adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith >nul 2>&1

echo [5/6] Enabling PatchWall button remapping...
adb shell settings put secure enabled_accessibility_services com.mihir.tvhome/com.mihir.tvhome.KeyRemapService >nul 2>&1
adb shell settings put secure accessibility_enabled 1 >nul 2>&1

echo [6/6] Refreshing Home screen...
adb shell am force-stop com.android.tv.settings
adb shell am force-stop com.mihir.tvhome
adb shell input keyevent KEYCODE_HOME

echo.
echo ===================================================
echo [SUCCESS] tv-home is now updated and configured!
echo - PatchWall button remapped directly to HDMI
echo - Weather widget & Adaptive UI active
echo - Bluetooth quick-connect pill active
echo - Screen Off / Sleep controls active
echo (To undo at any time, run: restore.bat)
echo ===================================================
