#!/usr/bin/env nextflow

process MACS2_CALLPEAK_BROAD {
    label 'process_medium'
    container = 'oras://community.wave.seqera.io/library/macs2:2.2.7.1--189209832f83d10b'
    publishDir "results/macs2/broad", mode: 'copy'

    input:
    tuple val(meta), path(exp_bam), path(exp_bai), path(ctrl_bam), path(ctrl_bai)

    output:
    tuple val(meta), path("*.{narrowPeak,broadPeak}"), emit: peak
    tuple val(meta), path("*.gappedPeak"), emit: gapped
    tuple val(meta), path("*.xls"), emit: xls

    script:
    def sample_id = meta.sample_id

    """
    macs2 callpeak \\
        --treatment ${exp_bam} \\
        --control ${ctrl_bam} \\
        --format BAMPE \\
        --gsize hs \\
        --name ${sample_id}_broad \\
        --broad --broad-cutoff 0.1 \\
        -q 0.05 \\
    """
}
