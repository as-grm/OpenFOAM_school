#!/usr/bin/env bash
#SBATCH --export=ALL,LD_PRELOAD=
#SBATCH --partition=rome
#SBATCH --mem=0
#SBATCH --ntasks 4
#SBATCH --ntasks-per-node=4
#SBATCH --job-name=OF_username
#SBATCH --output=output.txt
#SBATCH --error=error.txt

# Set OpenFOAM default module and setup environment
module purge
module load OpenFOAM
source $FOAM_BASH

# Run from this directory, where is the case!
cd "$(dirname -- "$(readlink -f -- "$0")")" || exit 1

# Source tutorial run functions
source $WM_PROJECT_DIR/bin/tools/RunFunctions

# decompose the case (number of decompositions is equal to --ntasks)
runApplication decomposePar
echo "Done with decomposition. Wait 3 sec to finish all jobs!"
sleep 3

# run parallel
echo "Start $(getApplication) in parallel. Log is written in output.txt!"
srun --mpi=pmix  $(getApplication) -parallel

# Check the running process with: tail -f output.txt
