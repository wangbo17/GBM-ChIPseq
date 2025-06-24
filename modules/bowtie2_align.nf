#!/usr/bin/env nextflow

process BOWTIE2_ALIGN {
    label 'process_medium'

    container = 'oras://community.wave.seqera.io/library/bowtie2_samtools:6df3a3213a70e258'
    publishDir "results/bowtie2/align", mode: 'copy'

    input:
    tuple val(meta), path(read1), path(read2)
    path bt2_index

    output:
    tuple val(meta), path("*.bam"), emit: 'bam'
    path "*.log", emit: 'log'

    script:
    def sample_id = meta.sample_id
    def group = meta.group

    """
    prefix_name=\$(basename \$(ls ${bt2_index}/*.1.bt2) | sed -E 's/\\.1\\.bt2\$//')
    prefix_path=${bt2_index}/\$prefix_name

    bowtie2 \\
        --end-to-end --very-sensitive --no-mixed --no-discordant \\
        --phred33 -I 10 -X 700 \\
        -x \$prefix_path \\
        -1 ${read1} -2 ${read2} \\
        --threads ${task.cpus} \\
        2> ${sample_id}.bowtie2.log \\
        | samtools sort -@ ${task.cpus} -o - - \\
        | samtools addreplacerg \\
            -r ID:${sample_id} -r SM:${group} \\
            -o ${sample_id}.rg.bam -
    """
}