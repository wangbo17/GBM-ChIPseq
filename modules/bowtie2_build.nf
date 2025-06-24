#!/usr/bin/env nextflow

process BOWTIE2_BUILD {
    label 'process_medium'

    container = 'oras://community.wave.seqera.io/library/bowtie2_samtools:6df3a3213a70e258'
    publishDir "results/bowtie2/build"

    input:
    path fasta_file

    output:
    path('bowtie2'), emit: 'bt2_index'

    script:
    """
    mkdir -p bowtie2
    bowtie2-build --threads ${task.cpus} ${fasta_file} bowtie2/${fasta_file.baseName}
    """

    stub:
    """
    mkdir -p bowtie2
    touch bowtie2/${fasta_file.baseName}.{1..4}.bt2
    touch bowtie2/${fasta_file.baseName}.rev.{1,2}.bt2
    """
}