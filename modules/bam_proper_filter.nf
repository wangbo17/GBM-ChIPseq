#!/usr/bin/env nextflow

process BAM_PROPER_FILTER {
    label 'process_low'

    container = 'oras://community.wave.seqera.io/library/samtools:1.22--105e5e643c53f059'
    publishDir "results/samtools/proper_filter", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam"), emit: 'bam'

    script:
    def sample_id = meta.sample_id

    """
    samtools view -f 3 -F 268 -@ ${task.cpus} -h -b ${bam} > ${sample_id}.bam
    # -f 3     : include only reads that are properly paired
    # -F 268   : exclude reads that are unmapped, have an unmapped mate, or are secondary alignments
    # -h       : retain the BAM header in the output
    """
}
