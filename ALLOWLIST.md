# allowlist-IP

Panduan lengkap: cara cek IP egress instance (molab dll) + daftarin ke relay `82.39.206.183:443`.

Worker di instance gak akan nyambung ke relay sebelum IP-nya di-allowlist. Ikuti ini sekali per instance.

---

## STEP 1 — Cek IP egress di instance molab

Jalankan di instance molab:

```bash
curl -s ifconfig.me && echo
```

Output-nya satu baris IP, contoh:

```
203.0.113.45
```

Catat IP itu.

Jika `curl ifconfig.me` gagal, alternatif:

```bash
curl -s icanhazip.com
# atau
curl -s https://api.ipify.org
```

---

## STEP 2 — Daftarkan IP ke relay

Jalankan di **VPS relay** (82.39.206.183), bukan di molab:

```bash
iptables -I INPUT 1 -p tcp --dport 443 -s <IP_MOLAB> -j ACCEPT
```

Contoh:

```bash
iptables -I INPUT 1 -p tcp --dport 443 -s 203.0.113.45 -j ACCEPT
```

Verifikasi rule masuk:

```bash
iptables -L INPUT -n --line-numbers | grep 443
```

Output yang benar:

```
1    ACCEPT     6    --  203.0.113.45   0.0.0.0/0    tcp dpt:443
2    ACCEPT     6    --  124.174.3.209   0.0.0.0/0    tcp dpt:443
3    ACCEPT     6    --  82.39.206.183    0.0.0.0/0    tcp dpt:443
4    DROP       6    --  0.0.0.0/0        0.0.0.0/0    tcp dpt:443
```

---

## STEP 3 — Test sambungan dari molab

Balik ke **instance molab**, jalankan:

```bash
timeout 10 bash -c 'echo > /dev/tcp/82.39.206.183/443' && echo "RELAY OK" || echo "BLOCKED"
```

- `RELAY OK` → lanjut start worker (`bash train.sh`)
- `BLOCKED` → IP salah / rule belum masuk → ulangi STEP 1-2

---

## STEP 4 — Simpan rule agar tidak hilang saat reboot

iptables by default hilang setelah reboot. Persist:

```bash
apt-get install -y iptables-persistent
netfilter-persistent save
```

Verifikasi file tersimpan:

```bash
ls -la /etc/iptables/rules.v4
```

---

## Hapus IP dari allowlist (kalau perlu)

```bash
iptables -D INPUT -p tcp --dport 443 -s <IP_MOLAB> -j ACCEPT
netfilter-persistent save
```

---

## Catatan

| Hal | Keterangan |
|---|---|
| IP molab ganti tiap restart instance? | Cek ulang STEP 1 setiap kali instance baru dibuat, ulangi STEP 2 |
| Mau buka relay untuk semua IP (tanpa allowlist)? | `iptables -D INPUT 2` (hapus rule DROP) — lebih gampang tapi siapa pun bisa numpang relay |
| Posisi rule penting | Rule ACCEPT IP harus di ATAS rule DROP. `-I INPUT 1` selalu menaruh paling atas — aman |
