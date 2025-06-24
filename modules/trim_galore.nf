#!/usr/bin/env nextflow

process TRIM_GALORE {
    label 'process_medium'

    container = 'oras://community.wave.seqera.io/library/trim-galore:0.6.10--bc38c9238980c80e'
    publishDir "results/trim_galore", mode: 'copy'

    input:
    tuple val(meta), path(read1), path(read2)

    output:
    tuple val(meta), path("*_val_1.fq.gz"), path("*_val_2.fq.gz"), emit: trimmed_reads
    path "*_trimming_report.txt", emit: trimming_reports
    path "*_val_1_fastqc.{zip,html}", emit: fastqc_reports_1
    path "*_val_2_fastqc.{zip,html}", emit: fastqc_reports_2

    script:
    def cores = 1
    if (task.cpus) {
        cores = (task.cpus as int) - 1
        if (cores < 1) cores = 1
        if (cores > 8) cores = 8
    }

    def sample_id = meta.sample_id

    """
    read1_name=\$(basename ${read1})
    read2_name=\$(basename ${read2})

    target1=${sample_id}_raw_1.fastq.gz
    target2=${sample_id}_raw_2.fastq.gz

    if [ "\$read1_name" != "\$target1" ]; then
        ln -s \$read1_name \$target1
    fi

    if [ "\$read2_name" != "\$target2" ]; then
        ln -s \$read2_name \$target2
    fi

    trim_galore \\
        --cores $cores \\
        --fastqc \\
        --paired \$target1 \$target2 \\
        --basename ${sample_id} \\
        --quality 25 \\
        --length 20 \\
        --stringency 3
    """
}