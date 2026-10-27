param (
    [switch]$Install
)

$ErrorActionPreference = "Stop"

# Detect JDK
$JavaHome = if ($env:JAVA_HOME -and (Test-Path $env:JAVA_HOME)) {
    $env:JAVA_HOME
} else {
    $jdkDir = Get-ChildItem "C:\Program Files\Java\jdk*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($jdkDir) { $jdkDir.FullName } else { $null }
}

if ($JavaHome) {
    $env:JAVA_HOME = $JavaHome
    $env:PATH = "$JavaHome\bin;$env:PATH"
    Write-Host "Using JDK: $JavaHome"
}

# Detect Android SDK
$AndroidSdk = if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
    $env:ANDROID_HOME
} else {
    "C:\Users\Mithilesh\AppData\Local\Android\Sdk"
}

$BT = Get-ChildItem "$AndroidSdk\build-tools" | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
$JAR = (Get-Item "$AndroidSdk\platforms\android-*\android.jar")[-1].FullName

Write-Host "Using Android SDK: $AndroidSdk"
Write-Host "Using Build-Tools: $BT"
Write-Host "Using Platform JAR: $JAR"

$LauncherDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $LauncherDir

$BuildDir = Join-Path $LauncherDir "build"
if (Test-Path $BuildDir) {
    Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Path (Join-Path $BuildDir "gen"), (Join-Path $BuildDir "classes"), (Join-Path $BuildDir "dex") -Force | Out-Null

Write-Host "1. Compiling resources (aapt2 compile)..."
& "$BT\aapt2.exe" compile --dir res -o (Join-Path $BuildDir "res.zip")
if ($LASTEXITCODE -ne 0) { throw "aapt2 compile failed" }

Write-Host "2. Linking resources and manifest (aapt2 link)..."
& "$BT\aapt2.exe" link -o (Join-Path $BuildDir "base.apk") -I $JAR --manifest AndroidManifest.xml --java (Join-Path $BuildDir "gen") -A assets --min-sdk-version 28 --target-sdk-version 28 (Join-Path $BuildDir "res.zip")
if ($LASTEXITCODE -ne 0) { throw "aapt2 link failed" }

Write-Host "3. Compiling Java classes (javac)..."
$javaFiles = Get-ChildItem -Recurse -Filter *.java src, (Join-Path $BuildDir "gen") | Select-Object -ExpandProperty FullName
javac -nowarn --release 11 -classpath $JAR -d (Join-Path $BuildDir "classes") $javaFiles
if ($LASTEXITCODE -ne 0) { throw "javac failed" }

Write-Host "4. Converting to DEX (d8)..."
$classFiles = Get-ChildItem -Recurse -Filter *.class (Join-Path $BuildDir "classes") | Select-Object -ExpandProperty FullName
& "$BT\d8.bat" --min-api 28 --lib $JAR --output (Join-Path $BuildDir "dex") $classFiles
if ($LASTEXITCODE -ne 0) { throw "d8 failed" }

Write-Host "5. Packaging APK (classes.dex into APK)..."
Copy-Item (Join-Path $BuildDir "base.apk") (Join-Path $BuildDir "unsigned.apk")
& jar -uf (Join-Path $BuildDir "unsigned.apk") -C (Join-Path $BuildDir "dex") classes.dex
if ($LASTEXITCODE -ne 0) { throw "jar packaging failed" }

Write-Host "6. Aligning APK (zipalign)..."
& "$BT\zipalign.exe" -f 4 (Join-Path $BuildDir "unsigned.apk") (Join-Path $BuildDir "aligned.apk")
if ($LASTEXITCODE -ne 0) { throw "zipalign failed" }

Write-Host "7. Signing APK (apksigner)..."
$Keystore = Join-Path $LauncherDir "debug.keystore"
if (-not (Test-Path $Keystore)) {
    & keytool -genkeypair -keystore $Keystore -storepass android -keypass android -alias tvhome -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=tvhome"
}
& "$BT\apksigner.bat" sign --ks $Keystore --ks-pass pass:android --out (Join-Path $BuildDir "tvhome.apk") (Join-Path $BuildDir "aligned.apk")
if ($LASTEXITCODE -ne 0) { throw "apksigner failed" }

$apkPath = Join-Path $BuildDir "tvhome.apk"
$apkSize = (Get-Item $apkPath).Length
Write-Host ""
Write-Host "[SUCCESS] Successfully built: $apkPath ($apkSize bytes)" -ForegroundColor Green

if ($Install) {
    Write-Host ""
    Write-Host "Installing to connected ADB device..." -ForegroundColor Cyan
    adb install -r $apkPath
    adb shell pm grant com.mihir.tvhome android.permission.ACCESS_FINE_LOCATION
    adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
    adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith
    adb shell cmd package set-home-activity --user 0 com.mihir.tvhome/.MainActivity
    adb shell am force-stop com.android.tv.settings
    adb shell input keyevent KEYCODE_HOME
    Write-Host ""
    Write-Host "[SUCCESS] Installed and set as default launcher! Check your TV." -ForegroundColor Green
}
