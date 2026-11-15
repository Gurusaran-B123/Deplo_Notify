"""Patches the Flutter-generated Android project for flutter_local_notifications.
Run from the project root after `flutter create`. Safe to run more than once."""
import pathlib

# ---------- AndroidManifest.xml ----------
manifest = pathlib.Path("android/app/src/main/AndroidManifest.xml")
m = manifest.read_text()

if "POST_NOTIFICATIONS" not in m:
    perms = """    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
"""
    receivers = """        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            </intent-filter>
        </receiver>
"""
    m = m.replace("<application", perms + "    <application", 1)
    m = m.replace("</application>", receivers + "    </application>", 1)
    manifest.write_text(m)
    print("Manifest patched")

# ---------- app/build.gradle(.kts) ----------
kts = pathlib.Path("android/app/build.gradle.kts")
groovy = pathlib.Path("android/app/build.gradle")

if kts.exists():
    g = kts.read_text()
    if "isCoreLibraryDesugaringEnabled" not in g:
        g = g.replace(
            "compileOptions {",
            "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
            1,
        )
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}\n'
        kts.write_text(g)
        print("build.gradle.kts patched")
elif groovy.exists():
    g = groovy.read_text()
    if "coreLibraryDesugaringEnabled" not in g:
        g = g.replace(
            "compileOptions {",
            "compileOptions {\n        coreLibraryDesugaringEnabled true",
            1,
        )
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'\n}\n"
        groovy.write_text(g)
        print("build.gradle patched")
else:
    raise SystemExit("No app build.gradle found")
