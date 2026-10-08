#!/usr/bin/env bash
# Lists hardcoded colors / font sizes / paddings left outside lib/core.
# Goal: no output = all screens read from design tokens.
cd "$(dirname "$0")/.." || exit 1
grep -rnE "Color\(0x|Colors\.[a-z]+|fontSize:\s*[0-9]|EdgeInsets\.[a-zA-Z]+\([^)]*[0-9]" lib \
  --include=*.dart --exclude-dir=core || echo "OK: no hardcoded style values found"
