# The Catid Dataloader

"I couldn't think of a better name." -catid

Optimized C++ dataloader for tokenized datasets, with simple Python bindings.  Tested as part of my own language model training scripts and now releasing separately for others to use.

Features:
* All operations are fully pipelined with training for zero delay.
* Compatible with any n_vocab size.
* Uses Zstd with byte planes to save a ton of disk space.
* Negligible memory usage (does not use memory-mapped files).
* Fast random-access disk IO achieved using liburing.
* All operations are full parallelized for speed.
* Uses an index file to accelerate data lookup.
* Hash to verify entire dataset integrity quickly.
* Supports fast checkpoint resume by skipping ahead a specified number of steps without re-reading.
* Short strings are concatenated and separated by padding tokens to improve training throughput.
* Supports seeded random access for reproducibility.

Benchmark results:

When pipelined with training, the dataloader takes approximately 0.01 milliseconds to read each microbatch, so basically it adds no delay to training.

Per 12 CPU cores on an SSD with a (huge) batch of 128 and context size of 8192, you can expect to achieve 6.25 milliseconds read speed per microbatch (measured in Python).


## Installation

Install the `catid_dataloader` pip package:

```bash
# Optional: Create a conda environment
conda create -n dataloader python=3.10 -y && conda activate dataloader

# Install build dependencies
sudo apt install build-essential cmake

# Install the package
pip install -U catid_dataloader
```

Verify that it is working:

```bash
git clone https://github.com/catid/dataloader.git
cd dataloader

python test_catid_dataloader.py
```


## Usage

From Python it looks like this:

```python
from catid_dataloader import DataLoader, DataVerifier, EpochConfig

loader = DataLoader(data_path)

config = EpochConfig()
config.seed0 = 1234 # Seed for shuffling the data.
config.seed1 = 5678
config.local_rank = 0 # GPU index on this node.
config.local_rank_count = 2 # Number of GPUs on this node.
config.padding_token = -1 # Token to use for padding.
config.micro_batch_size = 128 # Number of rows per micro-batch.
config.context_size = 8192 # Number of tokens per row.
# Minimum number of tokens in a string.  Note that short strings above this size are concatenated and separated by padding tokens.
config.min_data_length = 32
config.start_step = 0

loader.begin_epoch(config)

while True:
    batch, is_cont, step, total_steps = loader.get_micro_batch()
    if batch is None:
        print("Dataset exhausted")
        break
```

The `get_micro_batch()` method returns four values:
* The `batch` is a numpy tensor containing the tokenized text.
* The `is_cont` flag is set to `True` if the data is continued from the last step, for each batch row.
* The `step` (starting from 0, < total_steps) and `total_steps` are the current step and total number of steps in the dataset.

Each value returned will be `None` if the dataset is exhausted.

You can start from a specific step by setting the `start_step` parameter in the `EpochConfig` object, for resuming training from a checkpoint.  Note that the `context_size`, `micro_batch_size`, `min_data_length`, `local_rank`, `local_rank_count`, `seed0` and `seed1` parameters must be set to the same value as when the checkpoint was created, as otherwise the data at each step will not match the previous training run.


## Manual Installation from Source

Build and install the `catid_dataloader` pip package:

```bash
sudo apt install build-essential cmake

conda create -n dataloader python=3.10 -y && conda activate dataloader

./install.sh
```

Verify that it is working:

```bash
python python test_catid_dataloader.py
```


## Debugging

There are a few unit tests that can be run to verify the correctness of the code.  To run them, first build the project:

```bash
sudo apt install build-essential cmake

rm -rf build
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j

./test_compressor
./test_tools
./test_worker_pool
./test_mapped_file
./test_uring_file

./test_data_prep
./test_data_loader
```


## Credits

Latest versions of third-party libraries are included:

* `cityhash` from https://github.com/google/cityhash
* `cpppath` from https://github.com/tdegeus/cpppath
* `ryml` from https://github.com/biojppm/rapidyaml
* `liburing` from https://github.com/axboe/liburing
* `zstd` from https://github.com/facebook/zstd
