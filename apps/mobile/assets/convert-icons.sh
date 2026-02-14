#!/bin/bash
# Convert Haven SVG icons to PNG for mobile app
# Requires: ImageMagick (brew install imagemagick) or rsvg-convert (brew install librsvg)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Converting Haven icons to PNG..."

# Check for converter
if command -v convert &> /dev/null; then
    CONVERTER="imagemagick"
elif command -v rsvg-convert &> /dev/null; then
    CONVERTER="rsvg"
else
    echo "Error: Please install ImageMagick (brew install imagemagick) or librsvg (brew install librsvg)"
    exit 1
fi

convert_svg() {
    local input=$1
    local output=$2
    local size=$3
    
    if [ "$CONVERTER" = "imagemagick" ]; then
        convert -background none -density 300 "$input" -resize "${size}x${size}" "$output"
    else
        rsvg-convert -w "$size" -h "$size" "$input" -o "$output"
    fi
}

# App icon (1024x1024 for App Store)
echo "  → icon.png (1024x1024)"
convert_svg icon.svg icon.png 1024

# Adaptive icon for Android (1024x1024)
echo "  → adaptive-icon.png (1024x1024)"
convert_svg adaptive-icon.svg adaptive-icon.png 1024

# Splash screen (maintain aspect ratio for largest dimension)
echo "  → splash.png (1284x2778)"
if [ "$CONVERTER" = "imagemagick" ]; then
    convert -background "#6200EA" -density 300 splash.svg -resize 1284x2778 splash.png
else
    rsvg-convert -w 1284 -h 2778 splash.svg -o splash.png
fi

# Favicon (48x48 for web)
echo "  → favicon.png (48x48)"
convert_svg favicon.svg favicon.png 48

# Notification icon (96x96 for Android)
echo "  → notification-icon.png (96x96)"
convert_svg notification-icon.svg notification-icon.png 96

echo ""
echo "✓ All icons converted successfully!"
echo ""
echo "Generated files:"
ls -la *.png
