# Server Sendiri di Rumah

Mesin di rumah jadi server PPDB sungguhan: Nginx + PHP 8.3 + MySQL 8,
preview PPDB langsung jalan, bisa dibuka dari mana saja lewat tunnel gratis.
Tanpa kartu, tanpa sewa bulanan.

## Pakai dalam 4 langkah

1. **Pasang Ubuntu Server 24.04 LTS** di laptop lama / PC / Raspberry Pi
   (centang OpenSSH server saat instalasi).
2. **SSH dari laptop**, salin paket ini ke server:
   `scp -r server-rumah namamu@IP-SERVER:/tmp/`
3. **Jalankan setup** di server: `cd /tmp/server-rumah && bash setup-server-rumah.sh`
4. **Buka** `http://IP-SERVER/` — preview PPDB tampil
   (login demo: admin@sekolah.sch.id / password).

## Buka ke internet (pilih satu)

- **Cloudflare Tunnel** (publik, gratis, jalan di belakang CGNAT):
  `cloudflared tunnel login`, `cloudflared tunnel create ppdb` — detail di
  panduan langkah 5A.
- **Tailscale** (privat, hanya perangkatmu): `sudo tailscale up`.

Detail lengkap, perawatan, dan tahap Laravel ada di
`panduan-server-rumah.md`.
