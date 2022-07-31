#!/bin/bash
# Getting the path of the script excuted
script_dir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Model name (e.g. model.mat) is the first command-line argument passed to the shell script.
MATLAB_FILE=$1

# Number of iterations to perform is the second command-line argument passed to the shell script.
ITER=$2

# Getting Azure VM Instance ID
VM_ID=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/name?api-version=2017-08-01&format=text")

# Setting paths for INCA, input, and output
INCA_DIR=\'/home/matlabuser/inca_azure/INCAv1.8\'
INPUT_DIR=\'/mnt/modelfiles/input\'
OUTPUT_DIR=\'/mnt/modelfiles/output\'

# Running matlab script and exporting a log file
cd "$script_dir"
matlab nosplash -nodesktop -r "monteCarloSimulation('$VM_ID',$INCA_DIR,$INPUT_DIR,$OUTPUT_DIR,'$MATLAB_FILE',$ITER);exit;" |& tee -a /mnt/modelfiles/logs/monteCarloSimulation-$MATLAB_FILE-$VM_ID.txt

exit
