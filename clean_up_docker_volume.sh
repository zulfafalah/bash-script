#!/bin/bash

# Script untuk scan dan hapus Docker volumes
# Usage: ./clean_up_docker_volume.sh

set -e

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${BOLD}=== Docker Volume Scanner ===${NC}"
echo ""

# Cek docker tersedia
if ! command -v docker &>/dev/null; then
    echo -e "${RED}Error: Docker tidak ditemukan!${NC}"
    exit 1
fi

# Ambil semua volume
VOLUMES=$(docker volume ls --format "{{.Name}}" 2>/dev/null)

if [ -z "$VOLUMES" ]; then
    echo "Tidak ada Docker volume ditemukan."
    exit 0
fi

# Array untuk menyimpan data volume
declare -a VOL_NAMES
declare -a VOL_DRIVERS
declare -a VOL_SIZES
declare -a VOL_CONTAINERS
declare -a VOL_STATUS  # "used" atau "unused"

INDEX=0

echo -e "${DIM}Scanning volumes...${NC}"
echo ""

while IFS= read -r VOL; do
    [ -z "$VOL" ] && continue

    # Driver
    DRIVER=$(docker volume inspect "$VOL" --format "{{.Driver}}" 2>/dev/null || echo "unknown")

    # Ukuran volume (via du jika bisa, fallback ke N/A)
    MOUNTPOINT=$(docker volume inspect "$VOL" --format "{{.Mountpoint}}" 2>/dev/null || echo "")
    if [ -n "$MOUNTPOINT" ] && [ -d "$MOUNTPOINT" ]; then
        SIZE=$(du -sh "$MOUNTPOINT" 2>/dev/null | awk '{print $1}' || echo "N/A")
    else
        SIZE="N/A"
    fi

    # Container yang pakai volume ini (running + stopped)
    CONTAINERS_RAW=$(docker ps -a --filter "volume=$VOL" --format "{{.Names}}({{.Status}})" 2>/dev/null)
    if [ -z "$CONTAINERS_RAW" ]; then
        CONTAINERS_STR="(tidak dipakai)"
        STATUS="unused"
    else
        CONTAINERS_STR=$(echo "$CONTAINERS_RAW" | tr '\n' ', ' | sed 's/, $//')
        STATUS="used"
    fi

    VOL_NAMES[$INDEX]="$VOL"
    VOL_DRIVERS[$INDEX]="$DRIVER"
    VOL_SIZES[$INDEX]="$SIZE"
    VOL_CONTAINERS[$INDEX]="$CONTAINERS_STR"
    VOL_STATUS[$INDEX]="$STATUS"

    INDEX=$((INDEX + 1))
done <<< "$VOLUMES"

TOTAL=$INDEX

# Tampilkan tabel volume
printf "%-4s %-3s %-45s %-8s %-10s %s\n" "No" "[ ]" "Volume Name" "Driver" "Size" "Containers"
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────"

for i in $(seq 0 $((TOTAL - 1))); do
    if [ "${VOL_STATUS[$i]}" = "unused" ]; then
        STATUS_ICON="${YELLOW}●${NC}"
        CONTAINER_DISPLAY="${DIM}${VOL_CONTAINERS[$i]}${NC}"
    else
        STATUS_ICON="${GREEN}●${NC}"
        CONTAINER_DISPLAY="${VOL_CONTAINERS[$i]}"
    fi

    printf "%-4s " "$((i + 1))"
    echo -ne "[ ] "
    printf "%-45s %-8s %-10s " "${VOL_NAMES[$i]}" "${VOL_DRIVERS[$i]}" "${VOL_SIZES[$i]}"
    echo -e "$CONTAINER_DISPLAY"
done

echo ""
echo -e "Legend: ${GREEN}●${NC} Dipakai container  ${YELLOW}●${NC} Tidak dipakai (aman dihapus)"
echo ""

# Input seleksi
echo -e "${BOLD}Pilih volume yang ingin dihapus:${NC}"
echo -e "  Format: nomor dipisah koma atau spasi (contoh: ${CYAN}1,3,5${NC} atau ${CYAN}1 3 5${NC})"
echo -e "  Ketik ${CYAN}all-unused${NC} untuk pilih semua yang tidak dipakai"
echo -e "  Ketik ${CYAN}all${NC} untuk pilih semua"
echo -e "  Ketik ${CYAN}q${NC} untuk keluar"
echo ""
read -p "Pilihan: " SELECTION

echo ""

if [[ "$SELECTION" == "q" || -z "$SELECTION" ]]; then
    echo "Dibatalkan."
    exit 0
fi

# Parse seleksi
declare -a SELECTED_INDICES

if [[ "$SELECTION" == "all" ]]; then
    for i in $(seq 0 $((TOTAL - 1))); do
        SELECTED_INDICES+=("$i")
    done
elif [[ "$SELECTION" == "all-unused" ]]; then
    for i in $(seq 0 $((TOTAL - 1))); do
        if [ "${VOL_STATUS[$i]}" = "unused" ]; then
            SELECTED_INDICES+=("$i")
        fi
    done
else
    # Ganti koma dengan spasi lalu parse
    NORMALIZED=$(echo "$SELECTION" | tr ',' ' ')
    for NUM in $NORMALIZED; do
        if [[ "$NUM" =~ ^[0-9]+$ ]] && [ "$NUM" -ge 1 ] && [ "$NUM" -le "$TOTAL" ]; then
            SELECTED_INDICES+=("$((NUM - 1))")
        else
            echo -e "${YELLOW}⚠ Nomor tidak valid dilewati: $NUM${NC}"
        fi
    done
fi

if [ ${#SELECTED_INDICES[@]} -eq 0 ]; then
    echo "Tidak ada volume yang dipilih."
    exit 0
fi

# Tampilkan konfirmasi
echo -e "${BOLD}Volume yang akan dihapus:${NC}"
echo "──────────────────────────────────────────────────────────"
HAS_USED=false
for IDX in "${SELECTED_INDICES[@]}"; do
    VOL="${VOL_NAMES[$IDX]}"
    CONT="${VOL_CONTAINERS[$IDX]}"
    SZ="${VOL_SIZES[$IDX]}"
    if [ "${VOL_STATUS[$IDX]}" = "used" ]; then
        echo -e "  ${RED}✗ [DIPAKAI]${NC} $VOL ($SZ) → $CONT"
        HAS_USED=true
    else
        echo -e "  ${YELLOW}✓ [TIDAK DIPAKAI]${NC} $VOL ($SZ)"
    fi
done
echo "──────────────────────────────────────────────────────────"
echo ""

if [ "$HAS_USED" = true ]; then
    echo -e "${RED}⚠  PERINGATAN: Beberapa volume masih dipakai container!${NC}"
    echo -e "${RED}   Menghapus volume yang sedang dipakai bisa merusak container.${NC}"
    echo ""
fi

read -p "Lanjutkan hapus ${#SELECTED_INDICES[@]} volume? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Dibatalkan."
    exit 0
fi

echo ""
echo "Menghapus volumes..."
echo ""

DELETED=0
FAILED=0

for IDX in "${SELECTED_INDICES[@]}"; do
    VOL="${VOL_NAMES[$IDX]}"
    if docker volume rm "$VOL" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Berhasil:${NC} $VOL"
        DELETED=$((DELETED + 1))
    else
        echo -e "  ${RED}✗ Gagal:${NC} $VOL (mungkin masih dipakai container aktif)"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "════════════════════════════════════════════════════"
echo -e "  ${GREEN}✓ Berhasil dihapus: $DELETED volume${NC}"
if [ "$FAILED" -gt 0 ]; then
    echo -e "  ${RED}✗ Gagal dihapus  : $FAILED volume${NC}"
fi
echo "════════════════════════════════════════════════════"
echo ""
echo "=== Status Volume Docker Sekarang ==="
docker system df
echo ""
