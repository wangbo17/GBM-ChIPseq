#!/usr/bin/env nextflow

process BAM_MAPQ20_FILTER {
    label 'process_low'

    container = 'oras://community.wave.seqera.io/library/samtools:1.22--105e5e643c53f059'
    publishDir "results/samtools/mapq20_filter", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.filtered.dedup.bam"), emit: bam

    script:
    def sample_id = meta.sample_id

    """
    samtools view -q 20 -@ ${task.cpus} -h -b -o ${sample_id}.filtered.dedup.bam ${bam}
    # -q 20    : require mapping quality ≥ 20 to exclude ambiguous alignments
    """
}
