#!/bin/bash
# 
#SBATCH --partition day
#SBATCH --nodes 1
#SBATCH --ntasks-per-node=24 
#SBATCH --time=1440
#SBATCH --job-name="savu"
#SBATCH --output=/mnt/das-gpfs/home/ext-parsons_a/tmp/savu/savu.o%j
#SBATCH --error=/mnt/das-gpfs/home/ext-parsons_a/tmp/savu/savu.e%j

TMPDIR=/mnt/das-gpfs/home/ext-parsons_a/tmp/savu

filepath=$SAVUHOME/mpi/sls/savu_mpijob.sh
savupath=$(python -c "import savu, os; print savu.__path__[0]")
savupath=${savupath%/savu}
datafile=/mnt/das-gpfs/home/ext-parsons_a/workspace/Savu/test_data/data/mm.nxs 
processfile=/mnt/das-gpfs/home/ext-parsons_a/workspace/Savu/test_data/test_process_lists/MMtest.nxs
outpath=/mnt/das-gpfs/home/ext-parsons_a/
version=local
echo "*** savupath:" $savupath
echo "*** filepath:" $filepath
$filepath $savupath $datafile $processfile $outpath 24

