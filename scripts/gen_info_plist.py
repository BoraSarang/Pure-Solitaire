#!/usr/bin/env python3
"""Generate Info.plist for Pure Solitaire .app bundle."""
import os
import plistlib
import sys

def main() -> None:
    app_dir = sys.argv[1]
    version = os.environ.get("VERSION", "3.27.0")
    app_name = os.environ.get("APP_NAME", "Pure Solitaire")
    executable = os.environ.get("EXECUTABLE", "PureSolitaire")
    bundle_id = os.environ.get("BUNDLE_ID", "com.borasarang.puresolitaire")

    info = {
        "CFBundleName": app_name,
        "CFBundleDisplayName": "순수한 솔리테어",
        "CFBundleExecutable": executable,
        "CFBundleIdentifier": bundle_id,
        "CFBundleVersion": version,
        "CFBundleShortVersionString": version,
        "CFBundlePackageType": "APPL",
        "CFBundleIconFile": "AppIcon",
        "CFBundleIconName": "AppIcon",
        "CFBundleSupportedPlatforms": ["MacOSX"],
        "LSMinimumSystemVersion": "13.0",
        "LSApplicationCategoryType": "public.app-category.card-games",
        "NSHighResolutionCapable": True,
        "NSPrincipalClass": "NSApplication",
        "NSHumanReadableCopyright": "© 2026 Pure Solitaire",
    }

    path = os.path.join(app_dir, "Contents", "Info.plist")
    with open(path, "wb") as f:
        plistlib.dump(info, f, fmt=plistlib.FMT_XML)
    print("Info.plist 생성 완료:", path)


if __name__ == "__main__":
    main()