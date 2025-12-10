#!/bin/bash

# Script untuk menghapus Docker images yang tidak dipakai
# Usage: ./cleanup_docker.sh [months]
# Default: 3 bulan jika tidak ada parameter

set -e

# Fungsi untuk menampilkan cara pakai
show_usage() {
    echo "Usage: $0 [MONTHS]"
    echo ""
    echo "Menghapus Docker images yang tidak dipakai selama X bulan terakhir"
    echo ""
    echo "Arguments:"
    echo "  MONTHS    Jumlah bulan (default: 3)"
    echo ""
    echo "Examples:"
    echo "  $0        # Hapus images > 3 bulan"
    echo "  $0 6      # Hapus images > 6 bulan"
    echo "  $0 1      # Hapus images > 1 bulan"
    echo ""
    exit 1
}

# Parse parameter
MONTHS=${1:-3}

# Validasi input
if ! [[ "$MONTHS" =~ ^[0-9]+$ ]]; then
    echo "Error: Parameter harus berupa angka!"
    echo ""
    show_usage
fi

if [ "$MONTHS" -lt 1 ]; then
    echo "Error: Minimal 1 bulan!"
    echo ""
    show_usage
fi

echo "=== Docker Image Cleanup Script ==="
echo "Mencari images yang tidak dipakai lebih dari $MONTHS bulan..."
echo ""

# Hitung timestamp X bulan yang lalu (dalam detik)
MONTHS_AGO=$(date -d "$MONTHS months ago" +%s 2>/dev/null || date -v-${MONTHS}m +%s)

# Temporary file untuk menyimpan hasil
TEMP_FILE=$(mktemp)
IMAGES_TO_DELETE=""
COUNT=0
TOTAL_SIZE=0

# Dapatkan semua images
docker images --format "{{.ID}}|{{.Repository}}:{{.Tag}}|{{.Size}}|{{.CreatedAt}}" > "$TEMP_FILE"

# Proses setiap image
while IFS='|' read -r IMAGE_ID IMAGE_NAME IMAGE_SIZE CREATED_AT; do
    # Skip header atau baris kosong
    if [ -z "$IMAGE_ID" ]; then
        continue
    fi
    
    # Parse tanggal created - ambil hanya bagian tanggal
    CREATED_DATE=$(echo "$CREATED_AT" | awk '{print $1}')
    
    # Convert ke timestamp
    IMAGE_TIMESTAMP=$(date -d "$CREATED_DATE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$CREATED_DATE" +%s 2>/dev/null || echo "0")
    
    if [ "$IMAGE_TIMESTAMP" = "0" ]; then
        echo "⚠ Skip (gagal parse date): $IMAGE_NAME"
        continue
    fi
    
    # Cek apakah image lebih tua dari X bulan
    if [ "$IMAGE_TIMESTAMP" -lt "$MONTHS_AGO" ]; then
        # Cek apakah image sedang dipakai oleh container
        CONTAINERS_USING=$(docker ps -a --filter "ancestor=$IMAGE_ID" -q | wc -l | tr -d ' ')
        
        if [ "$CONTAINERS_USING" -eq 0 ]; then
            # Hitung umur dalam hari
            CURRENT_TIME=$(date +%s)
            AGE_DAYS=$(( ($CURRENT_TIME - $IMAGE_TIMESTAMP) / 86400 ))
            AGE_MONTHS=$(( $AGE_DAYS / 30 ))
            
            echo "✓ Akan dihapus: $IMAGE_NAME ($IMAGE_SIZE) - Umur: $AGE_MONTHS bulan ($AGE_DAYS hari)"
            IMAGES_TO_DELETE="$IMAGES_TO_DELETE $IMAGE_ID"
            COUNT=$((COUNT + 1))
        else
            echo "✗ Dilewati (masih dipakai): $IMAGE_NAME"
        fi
    fi
done < "$TEMP_FILE"

# Hapus temporary file
rm -f "$TEMP_FILE"

# Konfirmasi sebelum menghapus
if [ $COUNT -eq 0 ]; then
    echo ""
    echo "Tidak ada images yang perlu dihapus (kriteria: > $MONTHS bulan dan tidak dipakai)."
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "Total images yang akan dihapus: $COUNT"
echo "Kriteria: Tidak dipakai dan umur > $MONTHS bulan"
echo "════════════════════════════════════════════════════"
echo ""
read -p "Lanjutkan menghapus images? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Menghapus images..."
    DELETED=0
    FAILED=0
    
    for IMAGE_ID in $IMAGES_TO_DELETE; do
        if docker rmi -f "$IMAGE_ID" 2>/dev/null; then
            echo "✓ Berhasil menghapus: $IMAGE_ID"
            DELETED=$((DELETED + 1))
        else
            echo "✗ Gagal menghapus: $IMAGE_ID"
            FAILED=$((FAILED + 1))
        fi
    done
    
    echo ""
    echo "════════════════════════════════════════════════════"
    echo "✓ Cleanup selesai!"
    echo "   Berhasil dihapus: $DELETED images"
    if [ $FAILED -gt 0 ]; then
        echo "   Gagal dihapus: $FAILED images"
    fi
    echo "════════════════════════════════════════════════════"
    
    # Tampilkan ruang disk yang dibebaskan
    echo ""
    echo "=== Status Disk Docker ==="
    docker system df
    
    # Tanya apakah mau hapus build cache juga
    echo ""
    echo "════════════════════════════════════════════════════"
    echo "⚠  Build Cache terdeteksi!"
    docker system df | grep "Build Cache"
    echo "════════════════════════════════════════════════════"
    echo ""
    read -p "Hapus build cache juga? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Menghapus build cache..."
        if docker builder prune -af 2>/dev/null; then
            echo "✓ Build cache berhasil dihapus!"
        else
            echo "✗ Gagal menghapus build cache"
        fi
        
        echo ""
        echo "=== Status Disk Docker Setelah Cleanup Build Cache ==="
        docker system df
    else
        echo "Build cache tidak dihapus."
    fi
else
    echo "Cleanup dibatalkan."
fi