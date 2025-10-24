#!/bin/bash

# Usage:
#   bash prep_n_run.sh <input_vcf> [lines_per_file]
# Example:
#   bash prep_n_run.sh input/case_GS608_sv.vcf.gz 10000

# Check arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <input_vcf> [lines_per_file]"
    exit 1
fi

input_vcf="$1"
lines_per_file="${2:-10000}"  # Default to 10000 if not provided

# Get base name without extension
base=$(basename "$input_vcf" .vcf.gz)
bed_file="input/${base}.bed"

# Convert VCF to BED with filters
echo "Converting and sorting VCF to BED: $input_vcf -> $bed_file"
bcftools query -f '%CHROM\t%POS\t%INFO/END\t%INFO/SVTYPE\n' "$input_vcf" \
  | awk '$2 && $3 && $4 {print $1"\t"$2"\t"$3"\t"$4}' \
  | grep -v -E $'\t(INV|BND|DUP:INV|DUP:TANDEM)$' \
  | grep -E '^chr([1-9]|1[0-9]|2[0-2]|X|Y)[[:space:]]' \
  | grep -vE '_|random|alt|fix|hap|GL|KI' \
  | awk '$2 <= $3' \
  | sort -k1,1 -k2,2n \
  > "$bed_file"

# Split BED file into chunks
echo "Splitting BED file into chunks of $lines_per_file lines..."
split -l "$lines_per_file" "$bed_file" "input/id_${base}_part" --additional-suffix=.bed