#!/usr/bin/env nextflow

process MACS2_CALLPEAK_NARROW {
    label 'process_medium'
    container = 'oras://community.wave.seqera.io/library/macs2:2.2.7.1--189209832f83d10b'
    publishDir "results/macs2/narrow", mode: 'copy'

    input:
    tuple val(meta), path(exp_bam), path(exp_bai), path(ctrl_bam), path(ctrl_bai)

    output:
    tuple val(meta), path("*.{narrowPeak,broadPeak}"), emit: peak
    tuple val(meta), path("*.bed"), emit: bed
    tuple val(meta), path("*.xls"), emit: xls

    script:
    def sample_id = meta.sample_id

    """
    macs2 callpeak \\
        --treatment ${exp_bam} \\
        --control ${ctrl_bam} \\
        --format BAMPE \\
        --gsize hs \\
        --name ${sample_id}_narrow \\
        --call-summits \\
        -q 0.05
    """
}