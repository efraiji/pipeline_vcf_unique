#!/bin/bash
#SBATCH --account=def-acheng
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --job-name=snakemake_master
#SBATCH --output=logs/snakemake_master.%j.out

cd /lustre09/project/6100280/elenaf/pipeline_vcf_unique

snakemake \
    --profile workflow/profiles/default \
    --rerun-incomplete \
    --keep-going