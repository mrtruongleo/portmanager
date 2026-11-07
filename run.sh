#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# Kill running instance if any
pkill -x PortManager 2>/dev/null && echo "Stopped existing PortManager process." || true

if [ ! -d "PortManager.app" ] || [ "$1" == "--build" ]; then
    ./build_app.sh
fi

echo "🚀 Starting PortManager status bar app..."
open PortManager.app
echo "✨ PortManager is now running! Look for the network icon in your macOS status bar (top right)."

