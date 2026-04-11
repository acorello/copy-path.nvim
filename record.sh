#!/bin/bash
# One command to create the demo GIF.
# Run from this branch: bash record.sh

set -e

DEMO_DIR="/tmp/copy-path-demo"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Setup tmp demo project ──
rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR/src/utils" "$DEMO_DIR/.demo"

# Copy demo script only (plugin loaded via LazyVim)
cp "$SCRIPT_DIR/auto.lua" "$DEMO_DIR/.demo/"

# Create sample files
cat > "$DEMO_DIR/src/app.js" << 'EOF'
function greet(name) {
  return "Hello, " + name + "!";
}

function add(a, b) {
  return a + b;
}

function isEven(n) {
  return n % 2 === 0;
}

function max(a, b) {
  return a > b ? a : b;
}

function clamp(val, min, max) {
  if (val < min) return min;
  if (val > max) return max;
  return val;
}
EOF

cat > "$DEMO_DIR/src/utils/helpers.js" << 'EOF'
function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

function reverse(str) {
  return str.split("").reverse().join("");
}

function isPalindrome(str) {
  var cleaned = str.toLowerCase().replace(/[^a-z]/g, "");
  return cleaned === reverse(cleaned);
}

function range(start, end) {
  var result = [];
  for (var i = start; i < end; i++) {
    result.push(i);
  }
  return result;
}

function sum(arr) {
  return arr.reduce(function (a, b) { return a + b; }, 0);
}
EOF

# ── Record ──
cd "$DEMO_DIR"

CAST=".demo/demo.cast"
GIF_RAW=".demo/raw.gif"
GIF=".demo/demo.gif"

echo "==> Recording nvim session (this opens nvim — wait for it to finish)..."

asciinema rec "$CAST" --overwrite \
  -c "nvim src/app.js src/utils/helpers.js -c 'luafile .demo/auto.lua'"

echo "==> Converting to GIF..."

agg "$CAST" "$GIF_RAW" \
  --font-dir ~/Library/Fonts \
  --font-family "CaskaydiaCove Nerd Font" \
  --font-size 16 \
  --fps-cap 30 \
  --last-frame-duration 1

echo "==> Adding macOS window border..."

WIDTH=$(magick identify -format "%w" "${GIF_RAW}[0]")
HEIGHT=$(magick identify -format "%h" "${GIF_RAW}[0]")
BAR=36
PAD=12
BG="#282A36"
TW=$((WIDTH + PAD * 2))

magick -size "${TW}x${BAR}" "xc:${BG}" \
  -fill "#e78284" -draw "circle $((PAD+8)),18 $((PAD+8)),24" \
  -fill "#e5c890" -draw "circle $((PAD+28)),18 $((PAD+28)),24" \
  -fill "#a6d189" -draw "circle $((PAD+48)),18 $((PAD+48)),24" \
  /tmp/titlebar.png

magick "$GIF_RAW" -coalesce \
  -bordercolor "$BG" -border "${PAD}x0" \
  -background "$BG" -gravity north -splice "0x${BAR}" \
  -background "$BG" -gravity south -splice "0x${PAD}" \
  null: /tmp/titlebar.png -gravity NorthWest -geometry +0+0 -layers composite \
  -layers optimize \
  "$GIF"

rm -f /tmp/titlebar.png

# ── Copy GIF back and clean up ──
cp "$GIF" "$SCRIPT_DIR/demo.gif"
rm -rf "$DEMO_DIR"

FILESIZE=$(du -h "$SCRIPT_DIR/demo.gif" | cut -f1)
echo "==> Done! demo.gif ($FILESIZE)"
open "$SCRIPT_DIR/demo.gif"
