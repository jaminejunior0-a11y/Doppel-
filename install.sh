#!/data/data/com.termux/files/usr/bin/bash

APK="$HOME/DoppelNative/build/doppel-debug.apk"

echo "📦 Installing Doppel APK"
echo "========================"

# Check if APK exists
if [ ! -f "$APK" ]; then
    echo "❌ APK not found at $APK"
    echo "Run ./build-termux.sh first"
    exit 1
fi

echo "✅ APK found: $(ls -la $APK)"

# Copy to Downloads (accessible location)
echo "📁 Copying to /sdcard/Download/..."
cp "$APK" /sdcard/Download/doppel-debug.apk
echo "✅ Copied to /sdcard/Download/doppel-debug.apk"

# Open with system installer
echo "📱 Opening system installer..."
termux-open /sdcard/Download/doppel-debug.apk

echo ""
echo "👉 If the installer doesn't open automatically:"
echo "   - Open your file manager"
echo "   - Navigate to Downloads folder"
echo "   - Tap on doppel-debug.apk"
echo "   - Enable 'Install from unknown apps' if prompted"
