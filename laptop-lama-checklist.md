# Laptop Lama Jadi Server — Checklist Khusus

Paket utama ada di `panduan-server-rumah.md`. File ini hanya tambahan
khusus laptop — baca sebelum instalasi.

## 1. Cek dulu, layak atau tidak

Minimal: RAM 2 GB, storage 32 GB, CPU 64-bit (hampir semua laptop 2012
ke atas). Nyaman: RAM 4 GB, SSD 120 GB.

Kalau laptopnya masih Windows, cek di: **Settings > System > About**
(lihat RAM + prosesor) dan **File Explorer > This PC** (sisa storage).
Kalau sudah tidak bisa boot ke Windows, cek dari USB installer Ubuntu
nanti (menu "Try Ubuntu" tidak ada di Server — langsung instal saja,
spesifikasi bisa dicek setelah instal dengan `free -h` dan `df -h`).

## 2. Baterai — baca ini dulu, soal keselamatan

- **Baterai menggembung** (casing tidak rata, trackpad terangkat, keyboard
  menonjol): **JANGAN dipakai.** Lepas baterainya, jalankan laptop hanya
  dengan charger. Baterai lithium menggembung berisiko terbakar.
- **Baterai mati tapi tidak menggembung:** boleh dilepas atau dibiarkan;
  laptop jalan dengan charger saja.
- **Baterai masih sehat:** justru bagus — baterai jadi UPS gratis. Listrik
  padam sebentar, server tetap hidup.

## 3. Charger dan listrik

- Pakai charger asli. Charger murah yang tidak stabil bisa bikin laptop
  restart sendiri.
- Colok ke stopkontak yang tidak dimatikan saklarnya (banyak stopkontak
  rumah ikut saklar lampu).
- Listrik padam lama: laptop TIDAK menyala sendiri saat listrik kembali
  (tidak seperti PC yang ada pengaturan BIOS-nya). Kamu harus tekan tombol
  power. Kalau sering padam, baterai sehat (poin 2) adalah penyelamatnya.

## 4. Instalasi — kunci tombol per merek

- Buat USB installer seperti di panduan langkah 1 (Rufus, ISO Ubuntu
  Server 24.04).
- Boot menu (pilih USB): **ASUS** Esc/F8, **Lenovo** F12 atau tombol Novo,
  **HP** Esc lalu F9, **Acer** F12, **Dell** F12, **Toshiba** F12.
- Masuk BIOS (ubah urutan boot): **ASUS** F2/Del, **Lenovo** F2,
  **HP** Esc lalu F10, **Acer** F2/Del, **Dell** F2, **Toshiba** F2.
- Kalau USB tidak mau boot: masuk BIOS, matikan **Secure Boot** dulu.
  Ubuntu 24.04 umumnya bisa jalan dengan Secure Boot menyala, tapi laptop
  tua kadang rewel.

## 5. Setelah instal — 3 pengaturan wajib laptop

Jalankan di server (ini yang membuat laptop bisa jadi server beneran):

```bash
# 1. Tutup layar tidak bikin tidur
sudo nano /etc/systemd/logind.conf
# ubah baris HandleLidSwitch menjadi: HandleLidSwitch=ignore
sudo systemctl restart systemd-logind

# 2. Matikan sleep/suspend/hibernate
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 3. Matikan layar untuk hemat daya (layar boleh mati, mesin tetap jalan)
setterm --blank 1
```

## 6. Uji sebelum ditinggal

1. Tutup layar laptop — dari laptop utama, `ssh` ke server harus tetap
   bisa. Kalau putus, ulangi langkah 5 nomor 1.
2. `sudo reboot` — setelah nyala, SSH dan `http://IP-server/` harus
   kembali tampil tanpa disentuh.
3. Cabut charger 10 detik lalu colok lagi (kalau baterai dilepas, lewati
   tes ini) — server harus tetap hidup.
4. Bersihkan debu di lubang kipas sebelum dipakai 24 jam. Ganjal bagian
   belakang laptop 1-2 cm supaya udara masuk. Jangan taruh di dalam
   lemari tertutup.

## 7. LAN vs WiFi

Kabel LAN jauh lebih stabil untuk server. Kalau router jauh dari laptop,
pakai WiFi tidak apa-apa — installer Ubuntu Server bisa memasukkan nama
WiFi dan password saat instalasi. Tapi ingat: WiFi yang putus-nyambung
bikin tunnel ikut putus.
