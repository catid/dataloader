# High Performance Tokenized Dataset Sharding/Loading

The scripts convert downloaded HuggingFace datasets into our format by tokenizing the text and storing it in a custom format.  It pipelines downloading and sharding the dataset across multiple remote hosts in parallel.  It can be launched from a single machine for convenience.

Currently the `shard_dataset.py` script only works for HuggingFace datasets made up of Parquet files.  It is tested on Fineweb-Edu only so far.


## Setup

You can use the Ansible playbooks in the `ansible/` directory to set up the dependencies on each machine remotely with ease.

Currently I do not have a docker container for this, since probably it would make more sense to integrate this into your own docker container that includes the training code as well.

Or you can manually clone and install the repository at `~/dataloader` and install the C++ dataloader package on each machine in the `dataloader` conda environment, manually performing the steps performed by the Ansible playbooks.


## Shard and tokenize the dataset

This step will download and create local shards of the dataset on each training node.  Each node will have a fraction of the dataset.

Modify the `hosts.txt` file to point to the hosts you are using for training, and how many ranks (GPUs) are on each node.

Update the `--dataset-dir` parameter to the location of the dataset on your file server.  The `-output-dir` will be the same on each node.

In your repo checkout:

```bash
cd provision

conda activate dataloader

python make_shard_script.py --dataset-user "HuggingFaceFW" --dataset-name "fineweb-edu" --output-dir ~/dataset_shard
```

See the `make_shard_script.py --help` for more options.

This produces `run_all_hosts.sh`.  Run the dataset sharding job across the cluster:

```bash
sudo apt install pdsh parallel

./run_all_hosts.sh
```

If you hit CTRL+C it will abort the remote jobs.

This takes about ~10 hours for 4 machines on gigabit Internet using Fineweb-Edu 1.5T, and consumes 570GB disk space per node.

After this finishes, you'll have directories called `~/dataset_shard` and `~/holdout_shard` (0.1% of the dataset) with the sharded dataset and validation set on each node.
