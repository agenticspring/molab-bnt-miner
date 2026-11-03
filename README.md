# compute-worker

Lightweight compute worker manager untuk running distributed training jobs di instance sewaan (molab dll).

## Usage

```bash
bash train.sh            # start job (auto-detect cores)
bash train.sh start 4    # start dengan 4 lanes
bash train.sh list       # list job aktif
bash train.sh stop       # stop semua job
```

## Konfigurasi

Via environment variable (tanpa edit file):

```bash
JOB_ID=<job-id> bash train.sh        # id job/experiment
CLUSTER_NODE=<ip:port> bash train.sh # koordinator cluster
LANES=4 bash train.sh                # jumlah lanes (default: auto)
```

Default config ada di bagian atas `train.sh`.

## Struktur

- Runtime di-download sekali ke `/root/ml-work/engine`
- Log per-job: `/root/ml-work/logs/<run-id>.log`
- Job jalan di background (`setsid nohup`) — survive terminal close

## Monitoring

```bash
tail -f /root/ml-work/logs/*.log
bash train.sh list
```
