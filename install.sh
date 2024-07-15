#!/bin/bash
pip install build

rm -rf build dist catid_dataloader.egg-info && pip uninstall catid_dataloader -y
python -m build && pip install --force-reinstall dist/*.whl
