@echo off
echo ===================================================
echo Installing tv-home onto connected TV...
echo ===================================================

echo [1/5] Installing APK...
adb install -r "%~dp0launcher\build\tvhome.apk"
if errorlevel 1 (
    echo Installation failed. Is your TV connected via ADB?
    exit /b 1
)

echo [2/5] Granting permissions...
adb shell pm grant com.mihir.tvhome android.permission.ACCESS_FINE_LOCATION

echo [3/5] Setting tv-home as default launcher...
adb shell cmd package set-home-activity --user 0 com.mihir.tvhome/.MainActivity

echo [4/5] Disabling stock launcher (com.google.android.tvlauncher)...
adb shell pm disable-user --user 0 com.google.android.tvlauncher
rem In case of Google TV launcher:
adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx >nul 2>&1
adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith >nul 2>&1

echo [5/5] Refreshing Home screen...
adb shell am force-stop com.android.tv.settings
adb shell input keyevent KEYCODE_HOME

echo.
echo ===================================================
echo [SUCCESS] tv-home is now your default launcher!
echo Press the Home button on your TV remote to check.
echo (To undo at any time, run: restore.bat)
echo ===================================================
