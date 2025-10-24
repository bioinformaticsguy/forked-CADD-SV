#!/bin/bash
# This script runs the CADD-SV v1.1 using apptainer with the specified bindings and options.
# Usage: ./run_v1.1.2.sh [options] [arguments]
# Real Example: ./run_v1.1.2.sh -a input/id_test.bed.gz output/res.tsv.gz

module load singularity/v4.1.3

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 [-a] <input_file> <output_file>"
    exit 1
fi

if [[ $# -eq 3 && "$1" != "-a" ]]; then
    echo "Error: The first parameter, if present, must be -a."
    exit 1
fi

if [[ $# -eq 2 ]]; then
    input_file=$1
    output_file=$2
else
    annotation_flag=$1
    input_file=$2
    output_file=$3
fi

RUN_FOLDER=$(mktemp -d)
mkdir -p "${RUN_FOLDER}/input" "${RUN_FOLDER}/output" "${RUN_FOLDER}/beds"
cID=$(basename "$input_file" .bed.gz)
mkdir -p "${RUN_FOLDER}/${cID}"
chmod a+rwx "${RUN_FOLDER}/${cID}"

# ensure input exists on host and place it into the bound input folder
base_input=$(basename "$input_file")
base_output=$(basename "$output_file")
if [[ -f "$input_file" ]]; then
    ln -sf "$(realpath "$input_file")" "${RUN_FOLDER}/input/${base_input}"
else
    echo "Input file not found on host: $input_file"
    exit 1
fi

# container paths (inside bound tree)
container_input="/app/CADD-SV/input/${base_input}"
container_output="/app/CADD-SV/output/${base_output}"

singularity run \
    --bind /data/humangen_kircherlab/Users/hassan/repos/CADD-SV/annotations:/app/CADD-SV/annotations \
    --bind "${RUN_FOLDER}/input":/app/CADD-SV/input \
    --bind "${RUN_FOLDER}/output":/app/CADD-SV/output \
    --bind "${RUN_FOLDER}/beds":/app/CADD-SV/beds \
    --bind "${RUN_FOLDER}/${cID}":/app/CADD-SV/${cID} \
    --pwd "/app/CADD-SV/${cID}" \
    /data/humangen_kircherlab/Users/hassan/repos/CADD-SV/cadd-sv-1.1.2.sif \
    ${annotation_flag:+$annotation_flag} "$container_input" "$container_output"