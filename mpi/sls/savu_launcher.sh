#!/bin/bash
version=local
module load savu/$version

echo "SAVU_LAUNCHER:: Running Job"

datafile=$1
processfile=$2
outpath=$3
shift 3
options=$@

outname=savu
nNodes=2
nCoresPerNode=24
TMPDIR=~/tmp/savu
DIR="$(cd "$(dirname "$0")" && pwd)"
filepath=$DIR'/savu_mpijob.sh'
savupath=$(python -c "import savu, os; print savu.__path__[0]")
savupath=${savupath%/savu}

echo "*** savupath:" $savupath

M=$((nNodes*nCoresPerNode))

log_path=~/tmp/savu

while [[ $# -gt 1 ]]
do
if [ $1 == "-l" ]
  then
  log_path=$2
fi
shift
done



sbatch /mnt/das-gpfs/home/ext-parsons_a/workspace/Savu/mpi/sls/savu_slurm_file.sl

echo "SAVU_LAUNCHER:: Job Complete, preparing output..."

filename=`echo $outname.o`
jobnumber=`awk '{print $3}' $TMPDIR/$USER.out | head -n 1`
filename=$TMPDIR/$filename$jobnumber

while [ ! -f $filename ]
do
  sleep 2
done

echo "SAVU_LAUNCHER:: Output ready, spooling now"

cat $filename

echo "SAVU_LAUNCHER:: Process complete"

