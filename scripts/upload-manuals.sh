#!/bin/bash
# ============================================================================
# Haven Manual Upload Script
# Watches ~/Downloads/Haven-Manuals/ and uploads PDFs to Supabase
#
# FOLDER STRUCTURE:
#   ~/Downloads/Haven-Manuals/
#   ├── Samsung/
#   │   ├── RF29DB9900QDAA.pdf          → owners_manual for model RF29DB9900QDAA
#   │   ├── RF29DB9900QDAA_install.pdf  → installation_guide
#   │   └── RF29DB9900QDAA_spec.pdf     → spec_sheet
#   ├── Carrier/
#   │   ├── 24ACC636A003.pdf
#   │   └── 59SC5A080E21-20.pdf
#   └── GE/
#       └── GFE28GYNFS.pdf
#
# NAMING CONVENTION:
#   {MODEL_NUMBER}.pdf                  → uploads as owners_manual
#   {MODEL_NUMBER}_install.pdf          → uploads as installation_guide
#   {MODEL_NUMBER}_spec.pdf             → uploads as spec_sheet
#   {MODEL_NUMBER}_service.pdf          → uploads as service_manual
#   {MODEL_NUMBER}_parts.pdf            → uploads as parts_diagram
#   {MODEL_NUMBER}_quick.pdf            → uploads as quick_start_guide
#   {MODEL_NUMBER}_troubleshoot.pdf     → uploads as troubleshooting_guide
#
# USAGE:
#   ./scripts/upload-manuals.sh              # Process all PDFs in the folder
#   ./scripts/upload-manuals.sh --watch      # Watch for new files continuously
#   ./scripts/upload-manuals.sh --dry-run    # Show what would be uploaded
# ============================================================================

UPLOAD_DIR="$HOME/Downloads/Haven-Manuals"
PROCESSED_DIR="$UPLOAD_DIR/.processed"
FUNCTION_URL="https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/upload-manual"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DRY_RUN=false
WATCH=false

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --watch) WATCH=true ;;
  esac
done

mkdir -p "$PROCESSED_DIR"

# Determine manual type from filename suffix
get_manual_type() {
  local filename="$1"
  local base="${filename%.pdf}"

  case "$base" in
    *_install*)      echo "installation_guide" ;;
    *_spec*)         echo "spec_sheet" ;;
    *_service*)      echo "service_manual" ;;
    *_parts*)        echo "parts_diagram" ;;
    *_quick*)        echo "quick_start_guide" ;;
    *_troubleshoot*) echo "troubleshooting_guide" ;;
    *_warranty*)     echo "warranty_info" ;;
    *_energy*)       echo "energy_guide" ;;
    *)               echo "owners_manual" ;;
  esac
}

# Extract model number from filename (strip suffix)
get_model_number() {
  local filename="$1"
  local base="${filename%.pdf}"
  # Remove type suffixes
  base="${base%_install}"
  base="${base%_spec}"
  base="${base%_service}"
  base="${base%_parts}"
  base="${base%_quick}"
  base="${base%_troubleshoot}"
  base="${base%_warranty}"
  base="${base%_energy}"
  echo "$base"
}

upload_pdf() {
  local filepath="$1"
  local brand_dir="$2"
  local filename=$(basename "$filepath")
  local model_number=$(get_model_number "$filename")
  local manual_type=$(get_manual_type "$filename")

  echo -e "${BLUE}📄 ${brand_dir}/${filename}${NC}"
  echo -e "   Model: ${model_number}  Type: ${manual_type}"

  if [ "$DRY_RUN" = true ]; then
    echo -e "   ${YELLOW}[DRY RUN] Would upload${NC}"
    return
  fi

  # Upload via the Edge Function
  RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
    -F "file=@${filepath}" \
    -F "model_number=${model_number}" \
    -F "manual_type=${manual_type}" \
    2>&1)

  STATUS=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)
  ERROR=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('error',''))" 2>/dev/null)

  if [ "$STATUS" = "uploaded" ]; then
    SIZE=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('file_size_bytes',0))" 2>/dev/null)
    SIZE_KB=$((SIZE / 1024))
    echo -e "   ${GREEN}✓ Uploaded (${SIZE_KB} KB)${NC}"

    # Move to processed folder
    mkdir -p "$PROCESSED_DIR/$brand_dir"
    mv "$filepath" "$PROCESSED_DIR/$brand_dir/$filename"
  else
    echo -e "   ${RED}✗ Failed: ${ERROR}${NC}"
  fi
}

process_folder() {
  local count=0
  local success=0
  local failed=0

  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════${NC}"
  echo -e "${BLUE}  Haven Manual Upload — $(date '+%Y-%m-%d %H:%M')${NC}"
  echo -e "${BLUE}  Folder: ${UPLOAD_DIR}${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════${NC}"
  echo ""

  # Process each brand subfolder
  for brand_path in "$UPLOAD_DIR"/*/; do
    [ -d "$brand_path" ] || continue
    brand_dir=$(basename "$brand_path")

    # Skip the .processed folder
    [ "$brand_dir" = ".processed" ] && continue

    for pdf in "$brand_path"*.pdf; do
      [ -f "$pdf" ] || continue
      count=$((count + 1))
      upload_pdf "$pdf" "$brand_dir"
      echo ""
    done
  done

  # Also process PDFs directly in the root (no brand folder)
  for pdf in "$UPLOAD_DIR"/*.pdf; do
    [ -f "$pdf" ] || continue
    count=$((count + 1))
    echo -e "${YELLOW}⚠ PDF in root folder (no brand subfolder): $(basename "$pdf")${NC}"
    echo -e "  Move it into a brand folder like: ${UPLOAD_DIR}/Samsung/$(basename "$pdf")"
    echo ""
  done

  if [ $count -eq 0 ]; then
    echo -e "${YELLOW}No PDFs found.${NC}"
    echo ""
    echo "Drop PDFs into brand folders like:"
    echo "  ${UPLOAD_DIR}/Samsung/RF29DB9900QDAA.pdf"
    echo "  ${UPLOAD_DIR}/Carrier/24ACC636A003.pdf"
    echo "  ${UPLOAD_DIR}/GE/GFE28GYNFS_install.pdf"
  else
    echo -e "${GREEN}Processed ${count} files${NC}"
  fi
}

if [ "$WATCH" = true ]; then
  echo -e "${BLUE}👀 Watching ${UPLOAD_DIR} for new PDFs...${NC}"
  echo -e "${BLUE}   Press Ctrl+C to stop${NC}"
  echo ""

  # Initial scan
  process_folder

  # Watch for changes using fswatch (macOS) or inotifywait (Linux)
  if command -v fswatch &> /dev/null; then
    fswatch -0 -e ".*" -i "\\.pdf$" "$UPLOAD_DIR" | while read -d "" path; do
      sleep 1  # Wait for file to finish writing
      if [ -f "$path" ]; then
        brand_dir=$(basename "$(dirname "$path")")
        upload_pdf "$path" "$brand_dir"
      fi
    done
  else
    echo -e "${YELLOW}fswatch not found. Install with: brew install fswatch${NC}"
    echo "Falling back to polling every 30 seconds..."
    while true; do
      sleep 30
      process_folder
    done
  fi
else
  process_folder
fi
