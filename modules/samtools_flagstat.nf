#!/usr/bin/env nextflow

process SAMTOOLS_FLAGSTAT {
    label 'process_medium'

    container = 'oras://community.wave.seqera.io/library/samtools:1.22--105e5e643c53f059'
    publishDir "results/samtools/flagstat", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path("*.flagstat"), emit: 'flagstat'

    script:
    def sample_id = meta.sample_id
    
    """
    samtools \\
        flagstat \\
        --threads ${task.cpus} \\
        $bam \\
        > ${sample_id}.flagstat
    """
}
