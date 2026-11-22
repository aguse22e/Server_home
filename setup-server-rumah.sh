#!/bin/bash
# ============================================================================
# setup-server-rumah.sh — pasang server PPDB di mesin rumah (Ubuntu 24.04)
# Jalankan DI SERVER (laptop/PC/Raspberry Pi yang sudah terpasang Ubuntu
# Server 24.04), sebagai user biasa dengan sudo. Sekali jalan, +/- 15 menit.
#
# Yang dipasang:
#   1. Nginx + preview PPDB (statis, dari repo GitHub PPDB_SEKOLAH)
#   2. PHP 8.3 + ekstensi Laravel + Composer 2
#   3. MySQL 8 + database ppdb_db + user ppdb_user (password acak)
#   4. UFW (firewall: hanya SSH, HTTP, HTTPS)
#   5. cloudflared (Cloudflare Tunnel, akses internet tanpa IP publik)
#   6. Tailscale (akses privat dari HP/laptop, alternatif tunnel)
#
# Setelah skrip selesai, lanjut ke panduan-server-rumah.md langkah 5
# (buat tunnel Cloudflare) supaya PPDB bisa dibuka dari mana saja.
# ============================================================================
set -e

if ! command -v sudo >/dev/null 2>&1 && [ "$(id -u)" -ne 0 ]; then
  echo "Butuh sudo atau jalankan sebagai root."; exit 1
fi
SUDO="sudo"; [ "$(id -u)" -eq 0 ] && SUDO=""

echo "== 1/6 Paket dasar =="
$SUDO apt-get update -qq
DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq \
  nginx mysql-server curl git unzip ufw \
  php8.3 php8.3-cli php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-xml \
  php8.3-bcmath php8.3-curl php8.3-zip php8.3-gd php8.3-intl

echo "== 2/6 Composer =="
if ! command -v composer >/dev/null 2>&1; then
  curl -sS https://getcomposer.org/installer | $SUDO php -- \
    --install-dir=/usr/local/bin --filename=composer -q
fi
php -v | head -1; composer -V

echo "== 3/6 Preview PPDB (statis) di Nginx =="
$SUDO mkdir -p /var/www/ppdb
# Versi demo dari repo (akun demo tercantum di README repo PPDB_SEKOLAH).
# Akun master HANYA ada di berkas preview lokalmu, tidak ikut ke server.
# PENTING: sebelum preview dibuka ke internet, ganti password akun demo
# atau nonaktifkan akun demo itu, dan jangan isi data siswa asli ke preview demo.
curl -sL -o /tmp/ppdb-index.html \
  https://raw.githubusercontent.com/aguse22e/PPDB_SEKOLAH/main/index.html
$SUDO cp /tmp/ppdb-index.html /var/www/ppdb/index.html
$SUDO tee /etc/nginx/sites-available/ppdb >/dev/null <<'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/ppdb;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
$SUDO ln -sf /etc/nginx/sites-available/ppdb /etc/nginx/sites-enabled/ppdb
$SUDO rm -f /etc/nginx/sites-enabled/default
$SUDO nginx -t
$SUDO systemctl enable nginx mysql php8.3-fpm
$SUDO systemctl restart nginx mysql php8.3-fpm

echo "== 4/6 MySQL: database ppdb_db =="
DB_PASS=$(head -c 18 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)
$SUDO mysql -e "CREATE DATABASE IF NOT EXISTS ppdb_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
$SUDO mysql -e "CREATE USER IF NOT EXISTS 'ppdb_user'@'localhost' IDENTIFIED BY '$DB_PASS'; GRANT ALL PRIVILEGES ON ppdb_db.* TO 'ppdb_user'@'localhost'; FLUSH PRIVILEGES;"
umask 077
cat > "$HOME/.ppdb-db.txt" <<EOF
# Kredensial database PPDB di server rumah ini (jangan dibagikan)
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ppdb_db
DB_USERNAME=ppdb_user
DB_PASSWORD=$DB_PASS
EOF
chmod 600 "$HOME/.ppdb-db.txt"
echo "Kredensial database tersimpan di $HOME/.ppdb-db.txt (hanya bisa dibaca pemilik)"

echo "== 5/6 Firewall UFW =="
$SUDO ufw allow OpenSSH >/dev/null
$SUDO ufw allow 80/tcp >/dev/null
$SUDO ufw allow 443/tcp >/dev/null
$SUDO ufw --force enable >/dev/null

echo "== 6/6 cloudflared + Tailscale (akses dari internet) =="
ARCH=$(dpkg --print-architecture)
if ! command -v cloudflared >/dev/null 2>&1; then
  curl -sL -o /tmp/cloudflared.deb \
    "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb"
  $SUDO dpkg -i /tmp/cloudflared.deb || $SUDO apt-get install -f -y -qq
fi
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | $SUDO sh
fi
cloudflared --version | head -1; tailscale version | head -1

LAN_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "================ SELESAI ================"
echo "Preview PPDB di jaringan rumah:  http://$LAN_IP/"
echo "Login demo tercantum di README repo PPDB_SEKOLAH."
echo "PENTING: sebelum dibuka ke internet, ganti password akun demo"
echo "atau nonaktifkan akun demo itu, dan jangan isi data siswa asli."
echo "Database: ppdb_db (kredensial di $HOME/.ppdb-db.txt)"
echo ""
echo "LANJUTAN — biar bisa dibuka dari mana saja (pilih salah satu):"
echo "  A. Cloudflare Tunnel (publik, gratis): lihat panduan langkah 5A"
echo "     cloudflared tunnel login"
echo "     cloudflared tunnel create ppdb"
echo "  B. Tailscale (privat, hanya perangkatmu):"
echo "     sudo tailscale up"
echo "=========================================="
