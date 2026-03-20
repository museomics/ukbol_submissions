#!/usr/bin/env bash
set -euo pipefail

### Author: Maria Kamouyiaros @NHMUK
### Date: 2026-03-20

input_dir="$1"
output_dir="${2:-parsed_files}"

mkdir -p "$output_dir"

for FILE in "$input_dir"/*; do
    [[ -f "$FILE" ]] || continue

    sample_id=$(basename "$FILE")
    sample_id="${sample_id%%.*}"

    echo "Cleaning up file for $sample_id"

    sed -i 's/\r$//' "$FILE"

    echo "Processing $sample_id..."

    seqtk subseq ./*/assembled_sequence/"${sample_id}.fasta" "$FILE" \
        > "$output_dir/${sample_id}.fasta"

    grep -Fwf "$FILE" ./*/assess_assembly/*/"${sample_id}.bed" \
        > "$output_dir/${sample_id}.bed"
done

echo "Done."


## Example usage: bash parse_contig_assemblies_fun.sh input_dir output_dir
