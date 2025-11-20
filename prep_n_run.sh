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
chrom_len_file="$3"


# If chromosome size file is not provided, download hg38.chrom.sizes and use it
if [[ -z "$chrom_len_file" ]]; then
    chrom_len_file="hg38.chrom.sizes"
    if [[ ! -f "$chrom_len_file" ]]; then
        echo "Chromosome size file not provided. Downloading hg38.chrom.sizes..."
        wget -q http://hgdownload.cse.ucsc.edu/goldenpath/hg38/bigZips/hg38.chrom.sizes
    else
        echo "Using existing hg38.chrom.sizes file."
    fi
fi

# Get base name without extension
base=$(basename "$input_vcf" .vcf.gz)
base_dir=$(dirname "$input_vcf")
bed_file="input/${base}.bed"


#   | grep -v -E $'\t(INV|BND|DUP:INV|DUP:TANDEM)$' \

# Convert VCF to BED with filters
echo "Converting and sorting VCF to BED: $input_vcf -> $bed_file"
bcftools query -f '%CHROM\t%POS\t%INFO/END\t%INFO/SVTYPE\n' "$input_vcf" \
  | awk '$2 && $3 && $4 {print $1"\t"$2"\t"$3"\t"$4}' \
  | grep -v -E $'\t(INV|BND)$' \
  | sed 's/\tDUP:INV$/\tDUP/' | sed 's/\tDUP:TANDEM$/\tDUP/' \
  | grep -E '^chr([1-9]|1[0-9]|2[0-2]|X|Y)[[:space:]]' \
  | grep -vE '_|random|alt|fix|hap|GL|KI' \
  | awk '$2 <= $3' \
  | sort -k1,1 -k2,2n \
  > "$bed_file"

# this remves all the enteries whos end is beyond chrom length
# awk 'NR==FNR{a[$1]=$2; next} ($2 < $3) && ($3 <= a[$1])' "$chrom_len_file" "$bed_file" > "$base_dir/filtered.bed"
# mv "$base_dir/filtered.bed" "$bed_file"

## this edits the entries to fit within chrom length and also removes for start >= length of chromosome
# Clip BED entries to chromosome boundaries
awk 'NR==FNR{a[$1]=$2; next} {if($3 > a[$1]) $3 = a[$1]; if($2 > a[$1]) $2 = a[$1]; if($2 < $3) print $1"\t"$2"\t"$3"\t"$4}' "$chrom_len_file" "$bed_file" > "$base_dir/clipped.bed"
mv "$base_dir/clipped.bed" "$bed_file"


# Count lines in the filtered BED file
bed_lines=$(wc -l < "$bed_file")

if (( bed_lines >= lines_per_file )); then
    echo "Splitting BED file into chunks of $lines_per_file lines..."
    split -l "$lines_per_file" "$bed_file" "input/id_${base}_part" --additional-suffix=.bed
    rm "$bed_file"
else
    echo "BED file has less than $lines_per_file lines. Renaming with id_ prefix."
    mv "$bed_file" "input/id_${base}.bed"
fi