#!/usr/bin/env nextflow

process SAMTOOLS_IDXSTATS {
    label 'process_single'

    container = 'oras://community.wave.seqera.io/library/samtools:1.22--105e5e643c53f059'
    publishDir "results/samtools/idxstats", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path("*.idxstats"), emit: 'idxstats'

    script:
    def sample_id = meta.sample_id
    
    """
    samtools \\
        idxstats \\
        --threads ${task.cpus} \\
        $bam \\
        > ${sample_id}.idxstats
    """
}
