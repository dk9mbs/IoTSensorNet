#!/bin/bash

. ../init.sh

echo "PYTHONPATH: $PYTHONPATH"

python -m unittest discover -v
