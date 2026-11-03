# compute-worker

Lightweight compute worker manager untuk running training jobs di instance sewaan (molab dll).

## Prasyarat

- Instance Linux x86_64 (molab / VPS apa saja)
- Akses root atau sudo
- Koneksi internet (download runtime sekali saja, ±10 MB)
- RAM minimal 2 GB (lanes otomatis disesuaikan: maksimal setengah total RAM dalam GB)

---

## STEP 1 — Download & siapkan script

```bash
curl -fL -o train.sh https://raw.githubusercontent.com/agenticspring/molab-bnt-miner/main/train.sh
chmod +x train.sh
```

Verifikasi file ke-download:

```bash
ls -la train.sh
head -3 train.sh
```

---

## STEP 2 — Set wallet address (job id)

Wallet default sudah tertanam di script. Kalau mau pakai wallet lain, export dulu:

```bash
export JOB_ID=<WALLET_KAMU>
```

Cek wallet yang aktif di script:

```bash
grep "^JOB_ID=" train.sh
```

---

## STEP 3 — Start worker

Auto-detect cores dan RAM:

```bash
bash train.sh
```

Atau tentukan jumlah lanes secara manual:

```bash
bash train.sh start 4
```

Output yang benar (kurang lebih):

```
[1/3] setup runtime
[2/3] runtime size=XXXXXXX
[3/3] launching job run-1234-abc (lanes=N, cluster=82.39.206.183:443)
log: /root/ml-work/logs/run-XXXX-xxx.log
```

Jika `runtime not found` atau `fetch FAILED` → jalankan ulang STEP 3 (download bisa gagal karena jaringan).

---

## STEP 4 — Monitoring

Real-time log (cari baris `accepted` = share diterima pool):

```bash
tail -f /root/ml-work/logs/*.log
```

Daftar job aktif:

```bash
bash train.sh list
```

Ringkasan accepted per worker:

```bash
grep -h "accepted" /root/ml-work/logs/*.log | tail -20
```

---

## STEP 5 — Stop & bersih-bersih

Stop semua worker:

```bash
bash train.sh stop
```

Hapus semua data worker (runtime + log):

```bash
bash train.sh stop
rm -rf /root/ml-work
```

---

## Konfigurasi environment variable

| Variabel | Default | Fungsi |
|---|---|---|
| `JOB_ID` | tertanam di script | id job / wallet |
| `CLUSTER_NODE` | `82.39.206.183:443` | alamat koordinator |
| `LANES` | auto | jumlah lanes |

Contoh override:

```bash
JOB_ID=<WALLET> CLUSTER_NODE=<ip:port> bash train.sh
```

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| `fetch FAILED` | Jaringan ke github bermasalah — ulangi STEP 3, atau cek `curl -I https://github.com` |
| Log kosong / tidak ada `accepted` setelah 5 menit | Koneksi ke cluster ditolak — cek `CLUSTER_NODE` dan allowlist IP di sisi cluster |
| `runtime not found` | Arsip runtime berubah struktur — laporkan, script perlu update |
| CPU 100% terus | Normal (worker memang makan penuh). Kurangi `LANES` kalau perlu headroom |
| Worker mati sendiri setelah reboot | Jalankan lagi STEP 3 — job tidak auto-restart |
