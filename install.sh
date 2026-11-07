#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

if [ ! -d "PortManager.app" ]; then
    ./build_app.sh
fi

echo "📦 Installing PortManager.app to /Applications..."
rm -rf /Applications/PortManager.app
cp -R PortManager.app /Applications/

echo "✅ Installed to /Applications/PortManager.app"
echo "You can now launch it from Spotlight, Raycast, or Launchpad, or add it to Login Items!"

