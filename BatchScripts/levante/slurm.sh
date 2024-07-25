#!/bin/bash
#SBATCH --job-name=my_gpu_job      # Specify job name
#SBATCH --partition=gpu            # Specify partition name
#SBATCH --nodes=1                  # Specify number of nodes
#SBATCH --ntasks-per-node=1        # Specify number of (MPI) tasks on each node
#SBATCH --gpus-per-task=1          # Specify number of GPUs per task
#SBATCH --exclusive                # https://slurm.schedmd.com/sbatch.html#OPT_exclusive
#SBATCH --mem=0                    # Request all memory available on all nodes
#SBATCH --time=00:30:00            # Set a limit on the total run time
#SBATCH --mail-type=FAIL           # Notify user by email in case of job failure
#SBATCH --account=xz0123           # Charge resources on this project account
#SBATCH --output=my_job.o%j        # File name for standard output

set -e
ulimit -s 204800

# Check GPUs available for the job
# nvidia-smi

# Check GPUs visible for each task
# srun -l nvidia-smi

export JuliaDevice="GPU"
export JuliaGPU="CUDA"
export UCX_ERROR_SIGNALS=""
srun -n 1 gpu_wrapper.sh -n 1 -e "julia --project TestKernels/Race.jl
