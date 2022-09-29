#!/bin/bash --login

set +euo pipefail
conda activate base

set -euo pipefail

# The validation is not working as of now Therefor it is commented out
./tools/dist_train.sh configs/efficientLPS_multigpu_sample.py 1 --work_dir ../work_dirs/checkpoints #--validate 
