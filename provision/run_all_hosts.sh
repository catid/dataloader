#!/bin/bash
# Master script to execute shard_dataset.py on multiple hosts using parallel and pdsh


# Set trap to call the kill_remote_jobs function when SIGINT (CTRL+C) is received
kill_remote_jobs() {
    pdsh -R ssh -w gpu3.lan,gpu4.lan,gpu5.lan,gpu6.lan 'pkill -f shard_dataset.py'
}
trap 'kill_remote_jobs' SIGINT

parallel --halt-on-error now,fail=1 --lb ::: \
    "pdsh -R ssh -w gpu3.lan '"~/mambaforge/envs/dataloader/bin/python" "~/dataloader/dataset/shard_dataset.py" --dataset-user "HuggingFaceFW" --dataset-name "fineweb-edu" --rank-start 0 --rank-count 2 --world-size 8 --holdout-dir "holdout_shard" --holdout-rate 0.1'" \
    "pdsh -R ssh -w gpu4.lan '"~/mambaforge/envs/dataloader/bin/python" "~/dataloader/dataset/shard_dataset.py" --dataset-user "HuggingFaceFW" --dataset-name "fineweb-edu" --rank-start 2 --rank-count 2 --world-size 8 --holdout-dir "holdout_shard" --holdout-rate 0.1'" \
    "pdsh -R ssh -w gpu5.lan '"~/mambaforge/envs/dataloader/bin/python" "~/dataloader/dataset/shard_dataset.py" --dataset-user "HuggingFaceFW" --dataset-name "fineweb-edu" --rank-start 4 --rank-count 2 --world-size 8 --holdout-dir "holdout_shard" --holdout-rate 0.1'" \
    "pdsh -R ssh -w gpu6.lan '"~/mambaforge/envs/dataloader/bin/python" "~/dataloader/dataset/shard_dataset.py" --dataset-user "HuggingFaceFW" --dataset-name "fineweb-edu" --rank-start 6 --rank-count 2 --world-size 8 --holdout-dir "holdout_shard" --holdout-rate 0.1'"

trap - SIGINT
