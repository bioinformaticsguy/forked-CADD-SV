#!/bin/bash

#SBATCH --partition=shortterm
#SBATCH --nodes=1
#SBATCH -c 16
#SBATCH --mem=64GB
#SBATCH --tmp=100G
#SBATCH --output=logs/%j_%u_%N_testing_slurmJob.out
#SBATCH --error=logs/%j_%u_%N_testing_slurmJob.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=alihassan1697@gmail.com


# Load required modules
module load singularity/v4.1.3

# Update-path
PATH=/work/hassan/hassan/miniforge:$PATH
source /work/hassan/hassan/miniforge/etc/profile.d/conda.sh


# Activate Conda environment
conda activate run.caddsv


# Diagnostic: print current conda environment
conda info --envs
echo "CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV}"
echo "CONDA_PREFIX=${CONDA_PREFIX}"


# Run CADD-SV using Snakemake
snakemake  --use-conda --configfile config.yml -j 16