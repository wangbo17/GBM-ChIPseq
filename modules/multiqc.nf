#!/usr/bin/env nextflow

process MULTIQC {
    label 'process_single'

    container = 'oras://community.wave.seqera.io/library/multiqc:1.29--8e22d300f136081a'
    publishDir "results/multiqc", mode: 'copy'

    input:
    path '*'
    val output_name

    output:
    path "${output_name}.html", emit: report
    path "${output_name}_data", emit: data

    script:
    """
    multiqc . -n ${output_name}.html
    """
}
