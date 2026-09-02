#!/bin/bash
set -e

echo "=== Installing Flutter SDK ==="
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

export PATH="$PATH:`pwd`/flutter/bin"

echo "=== Flutter version ==="
flutter --version

echo "=== Building Flutter Web Release ==="
flutter build web --release --no-tree-shake-icons

echo "=== Flutter Web Build Complete ==="
