#!/bin/bash
#SBATCH --job-name=chipseq
#SBATCH --output=chipseq.out
#SBATCH --error=chipseq.err
#SBATCH --time=48:00:00
#SBATCH --mem=4G

conda activate nf_env
nextflow run chipseq.nf -resume