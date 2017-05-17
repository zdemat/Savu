#!/bin/bash
export PATH=$HOME/python/miniconda/bin:$PATH
export PATH=/mnt/das-gpfs/home/ext-parsons_a/python/anaconda2/bin:$PATH
export MODULEPATH=$MODULEPATH:/mnt/das-gpfs/home/ext-parsons_a/privatemodules/
export SAVUHOME=/mnt/das-gpfs/home/ext-parsons_a//workspace/Savu/

module load savu/local

savupath=$1
datafile=$2
processfile=$3
outfile=$4
nCPUs=$5
nGPUs=$6
shift 6
echo "PYTHON PATH IS" $PYTHONPATH
echo "LIBRARYPATH IS" $LD_LIBRARY_PATH
echo "PATH IS" $PATH
echo "PYTHON IS" `which python`
filename=$savupath/savu/tomo_recon.py

UNIQHOSTS=${TMPDIR}/machines-u
awk '{print $1 }' ${PE_HOSTFILE} | uniq > ${UNIQHOSTS}
uniqslots=$(wc -l <${UNIQHOSTS})
echo "number of uniq hosts: ${uniqslots}"
echo "running on these hosts:"
cat ${UNIQHOSTS}

processes=`bc <<< "$((uniqslots*nCPUs))"`

for i in $(seq 0 $((nGPUs-1))); do GPUs+="GPU$i " ; done
for i in $(seq 0 $((nCPUs-1-nGPUs))); do CPUs+="CPU$i " ; done
CPUs=$(echo $GPUs$CPUs | tr ' ' ,)
echo $CPUs

echo "Processes running are : ${processes}"

mpirun -np ${processes} \
       -mca btl self,openib,sm \
       -mca orte_forward_job_control 1 \
       -x LD_LIBRARY_PATH \
       --hostfile ${UNIQHOSTS} \
       python $filename $datafile $processfile $outfile -n $CPUs #-v $@
