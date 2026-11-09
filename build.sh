#!/bin/bash
set -e

echo "=== Setting up Flutter SDK for Vercel Build ==="

# Clone Flutter stable if not already present
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable branch)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
else
  echo "Using existing Flutter directory..."
fi

# Add Flutter binary to current environment PATH
export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Verifying Flutter Installation ==="
flutter --version

echo "=== Getting Flutter Packages ==="
flutter pub get

echo "=== Building Flutter Web Release ==="
flutter build web --release --no-tree-shake-icons

echo "=== Flutter Web Build Finished Successfully ==="
