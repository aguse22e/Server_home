# Server Sendiri di Rumah — Panduan Lengkap

Mesin di rumah jadi server sungguhan: preview PPDB jalan di Nginx, Laravel
siap dipasang, dan bisa dibuka dari mana saja lewat tunnel gratis.
Tanpa kartu, tanpa sewa bulanan. Yang dibayar cuma listrik.

## 0. Yang dibutuhkan

- **Mesin:** laptop lama, PC rakitan, mini PC, atau Raspberry Pi 4/5
  (RAM minimal 2 GB, disarankan 4 GB; storage minimal 32 GB).
- **Flashdisk 8 GB** untuk installer (kecuali Raspberry Pi, pakai microSD +
  Raspberry Pi Imager).
- **Kabel LAN** (lebih stabil dari WiFi) atau WiFi yang sinyalnya kuat.
- **Laptop utama** untuk SSH dan mengatur server.
- Waktu: +/- 1 jam dari nol sampai preview tampil.

Perkiraan listrik (PLN +/- Rp1.444/kWh): laptop 30-60 watt = sekitar
Rp30-60 ribu/bulan kalau nyala 24 jam. Mini PC / Raspberry Pi 5-15 watt =
sekitar Rp5-15 ribu/bulan.

## 1. Pasang Ubuntu Server 24.04 LTS

1. Unduh ISO **Ubuntu Server 24.04 LTS** dari ubuntu.com/download/server
   (untuk Raspberry Pi, pakai **Raspberry Pi Imager** dan pilih
   "Ubuntu Server 24.04 LTS (64-bit)" — tidak perlu flashdisk).
2. Buat USB bootable dengan **Rufus** (Windows) atau **balenaEtcher**,
   pilih ISO tadi.
3. Colok USB ke mesin server, nyalakan, masuk BIOS/boot menu
   (biasanya F2/F12/Del), boot dari USB.
4. Ikuti installer: bahasa Inggris, keyboard, pilih "Install Ubuntu Server".
   Saat ditanya paket tambahan, centang **OpenSSH server**.
5. Buat user + password (catat!), tunggu instalasi selesai, cabut USB,
   reboot.

Catatan laptop: setelah instal, atur agar laptop tidak tidur saat layar
ditutup (lihat langkah 7).

## 2. Masuk ke server dari laptop

1. Di server, ketik `hostname -I` — catat IP-nya (contoh: 192.168.1.50).
2. Dari laptop (Windows: PowerShell / Terminal; Mac/Linux: terminal):
   ```
   ssh namamu@192.168.1.50
   ```
   Masukkan password user server. Kalau berhasil, kamu sudah di dalam server.
3. Supaya IP tidak berubah-ubah: buka pengaturan router (biasanya
   192.168.1.1), cari DHCP Reservation / Address Reservation, kunci IP
   tadi ke MAC address mesin server. Kalau tidak ada menu itu, lewati dulu
   — langkah ini hanya kenyamanan.

## 3. Jalankan skrip setup (15 menit)

1. Salin isi paket ini ke server (dari laptop):
   ```
   scp -r server-rumah namamu@192.168.1.50:/tmp/
   ```
   (atau: `git clone` tidak diperlukan — paket ini sudah berisi semuanya.)
2. Di server:
   ```
   cd /tmp/server-rumah
   bash setup-server-rumah.sh
   ```
   Skrip memasang Nginx, PHP 8.3 + ekstensi Laravel, Composer 2, MySQL 8,
   firewall, cloudflared, dan Tailscale. Preview PPDB ikut terpasang.
3. Buka di browser laptop: `http://192.168.1.50/` (ganti IP dengan IP
   servermu). Preview PPDB harus tampil. Login demo tercantum di README
   repo PPDB_SEKOLAH.

Keamanan: yang terpasang di server adalah versi demo dari repo publik.
Akun master hanya ada di berkas preview lokalmu dan tidak ikut ke server
— memang begitu seharusnya untuk sesuatu yang dibuka ke internet.
Sebelum dibuka ke internet (langkah 5), ganti password akun demo atau
nonaktifkan akun demo itu, dan jangan isi data siswa asli ke preview demo.

## 4. Cek cepat (kalau ada yang tidak tampil)

| Gejala | Periksa |
|---|---|
| Browser tidak bisa buka IP | `sudo systemctl status nginx` di server; cek laptop dan server satu WiFi/LAN yang sama |
| Halaman Nginx default | Skrip sudah menghapus site default; jalankan `sudo nginx -t && sudo systemctl restart nginx` |
| `bash: sudo: command not found` | Login sebagai root, jalankan skrip tanpa sudo |
| MySQL tidak jalan | `sudo systemctl status mysql`, lalu `sudo systemctl restart mysql` |
| Lupa password database | Baca `~/.ppdb-db.txt` di server (file itu hanya bisa dibaca pemiliknya) |

## 5. Buka ke internet — pilih salah satu

### 5A. Cloudflare Tunnel (disarankan — publik, gratis, tanpa port forwarding)

Kenapa ini yang disarankan: kebanyakan internet rumah Indonesia (IndiHome
dsb.) memakai CGNAT — tidak ada IP publik, jadi port forwarding tidak bisa.
Tunnel keluar dari server ke Cloudflare, jadi tidak butuh IP publik sama
sekali. Perlu akun Cloudflare gratis + satu domain (bisa subdomain gratis
dari layanan seperti duckdns.org, atau domain sendiri).

Di server:
```
cloudflared tunnel login
```
(Buka tautan yang muncul di browser laptop, login Cloudflare, pilih domain.)

```
cloudflared tunnel create ppdb
cloudflared tunnel route dns ppdb ppdb.namadomainkamu.com
```

Buat config `/home/namamu/.cloudflared/config.yml`:
```yaml
tunnel: ppdb
credentials-file: /home/namamu/.cloudflared/<ID-TUNNEL>.json
ingress:
  - hostname: ppdb.namadomainkamu.com
    service: http://localhost:80
  - service: http_status:404
```

Jalankan sebagai service supaya hidup terus:
```
sudo cloudflared service install
sudo systemctl start cloudflared
```

Buka `https://ppdb.namadomainkamu.com` dari HP — preview PPDB tampil
dengan HTTPS otomatis.

### 5B. Tailscale (privat — hanya perangkatmu yang bisa buka)

Kalau belum mau publik, ini yang paling cepat:
```
sudo tailscale up
```
Buka tautan login, masuk dengan akun Google/GitHub. Instal Tailscale di
HP/laptop, login akun yang sama. Buka `http://<IP-Tailscale-server>/` —
PPDB bisa dibuka dari mana saja, tapi hanya oleh perangkat yang login
ke jaringan Tailscale-mu. Gratis untuk pemakaian pribadi.

### 5C. Port forwarding (hanya kalau ISP memberi IP publik)

Cek dulu: buka whatismyipaddress.com di server — kalau IP itu sama dengan
IP WAN di router, kamu punya IP publik. Kalau beda, kamu di belakang CGNAT
dan cara ini tidak bisa — pakai 5A atau 5B. Kalau bisa: di router, teruskan
port 80 ke IP server, dan pasang HTTPS dengan Certbot (`sudo certbot
--nginx`). Cara ini membuka port ke internet — pastikan password SSH kuat
dan lebih baik matikan login password (pakai kunci SSH saja).

## 6. Tahap 2 — Laravel PPDB lengkap (setelah preview live)

PHP, Composer, dan MySQL sudah terpasang oleh skrip setup. Tinggal ikut
`PANDUAN-INSTALL.md` dari paket Laravel (ada di repo GitHub PPDB_SEKOLAH,
folder `laravel/`, dan berkas `PANDUAN-INSTALL.md`):

```
git clone https://github.com/aguse22e/PPDB_SEKOLAH.git
cd PPDB_SEKOLAH
composer create-project laravel/laravel ppdb-sekolah
# ... salin isi folder laravel/ ke ppdb-sekolah, buat database,
# atur .env (kredensial ada di ~/.ppdb-db.txt), lalu:
php artisan migrate:fresh --seed
```

Jangan pasang Breeze/Jetstream/Fortify — paket PPDB sudah punya auth
sendiri dan route-nya akan bentrok. Node.js tidak dibutuhkan (tampilan
memakai Bootstrap via CDN).

## 7. Perawatan mesin

- **Laptop jangan tidur saat layar ditutup:** edit
  `/etc/systemd/logind.conf`, ubah `HandleLidSwitch=ignore`, lalu
  `sudo systemctl restart systemd-logind`.
- **Matikan sleep otomatis:** `sudo systemctl mask sleep.target
  suspend.target hibernate.target hybrid-sleep.target`.
- **Update berkala:** `sudo apt update && sudo apt upgrade -y` seminggu
  sekali (atau pasang `unattended-upgrades`).
- **Backup database:** `mysqldump -u ppdb_user -p ppdb_db > backup.sql`
  sebelum mengubah skema atau update besar.
- **Cek suhu:** laptop tua yang 24 jam menyala butuh alas dengan sirkulasi
  udara. Kalau kipas berisik terus, bersihkan debu dulu.
- **Listrik padam:** setelah listrik kembali, mesin menyala sendiri hanya
  kalau BIOS diatur "Power on after power failure" — cek pengaturan BIOS
  (untuk laptop, biasanya tidak ada opsi ini; colok ke UPS kecil kalau
  sering padam).

## 8. Batasannya, jujur

- Kecepatan tergantung internet rumah (upload IndiHome biasanya 20-50 Mbps
  — cukup untuk demo PPDB, kurang untuk traffic besar).
- Kalau listrik atau internet rumah padam, server ikut padam. Untuk demo
  dan pemakaian pribadi ini wajar; untuk produksi sekolah, Oracle Always
  Free tetap lebih stabil.
- Jangan simpan data penting hanya di satu mesin tanpa backup.
