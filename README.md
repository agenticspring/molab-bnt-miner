# molab-bnt-miner

Mining BNT (Blocknet) di instance molab pakai seine miner. **Address wallet = punya lo** (bisa dioverride via env).

> Script ini versi bersih dari script milik temen — base64 berlapis dibuang, telemetri palsu (formula "loss/epoch" yang ditanam manual) dihapus. Log yang keluar sekarang **output asli miner** (hashrate nyata, share accepted/rejected).

## Setup (sekali)

```bash
bash ml-run.sh
```

- Auto-download binary seine (Linux x86_64) ke `/root/ml-work/engine`
- Auto-detect cores + RAM → set jumlah lanes (maks setengah RAM GB, maks total cores)
- Start worker di background (`setsid nohup`) → survive terminal close
- Log per-worker: `/root/ml-work/logs/<worker>.log`

Override jumlah lanes (opsional):
```bash
LANES=4 bash ml-run.sh
```

Override wallet/pool (opsional, tanpa edit file):
```bash
BNT_ADDRESS=<wallet_lain> bash ml-run.sh
BNT_NODE=<ip:port> bash ml-run.sh
```

## Monitoring

```bash
# log real-time (cari "accepted" = share diterima pool)
tail -f /root/ml-work/logs/*.log

# daftar worker aktif
bash ml-run.sh list

# matikan semua worker
bash ml-run.sh stop
```

Cek balance/payout di pool: buka endpoint pool yang dipakai (default `43.163.84.133:13333`) dan query address lu.

## Catatan penting

| Hal | Keterangan |
|---|---|
| Wallet | Default `PLMG...GQc` (punya lo). Hasil mining masuk ke address yang dikirim ke pool — pastiin address di log sama kayak punya lo sebelum ninggalin jalan lama |
| Pool | Default nembak `43.163.84.133:13333` (pool temenmu). Bisa ganti via `BNT_NODE` |
| ToS molab | Running crypto miner di platform komputasi sewaan biasanya langgar ToS — akun bisa dibanned + sisa saldo hangus. Risiko lu sendiri |
| Versi temenmu | Punya dia nulis log mining ke file hidden `.train_raw_*.log` + bikin telemetri training palsu. Versi ini nggak — semua keliatan |
