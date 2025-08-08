#!/usr/bin/env nextflow

// Module INCLUDE statements
include { FASTQC } from './modules/fastqc.nf'
include { TRIM_GALORE } from './modules/trim_galore.nf'
include { BOWTIE2_BUILD } from './modules/bowtie2_build.nf'
include { BOWTIE2_ALIGN } from './modules/bowtie2_align.nf'

include { BAM_PROPER_FILTER } from './modules/bam_proper_filter.nf'
include { PICARD_MARKDUPLICATES } from './modules/picard_markduplicates.nf'
include { BAM_MAPQ20_FILTER } from './modules/bam_mapq20_filter.nf'

include { SAMTOOLS_INDEX } from './modules/samtools_index.nf'
include { SAMTOOLS_STATS } from './modules/samtools_stats.nf'
include { SAMTOOLS_IDXSTATS } from './modules/samtools_idxstats.nf'
include { SAMTOOLS_FLAGSTAT } from './modules/samtools_flagstat.nf'

include { MACS2_CALLPEAK_NARROW } from './modules/macs2_callpeak_narrow.nf'
include { MACS2_CALLPEAK_BROAD } from './modules/macs2_callpeak_broad.nf'

include { MULTIQC } from './modules/multiqc.nf'

/*
 * Pipeline parameters
 */

// Primary input
params.input_csv = "data/samplesheet.csv"
params.blacklist = "data/hg38-blacklist.bed"
params.fasta = "data/GRCh38.primary_assembly.genome.fa"
params.gtf = "data/gencode.v48.primary_assembly.annotation.gtf"
params.report_id = "chipseq"

log.info """\
==================================================================================================
\033[36m             ____ ____  __  __    ____ _     ___            ____             
            / ___| __ )|  \\/  |  / ___| |__ |_ _|_ __      / ___|  ___  __ _ 
           | |  _|  _ \\| |\\/| | | |   | '_ \\ | || '_ \\ ____\\___ \\ / _ \\/ _` |
           | |_| | |_) | |  | | | |___| | | || || |_) |_____|__) |  __/ (_| |
            \\____|____/|_|  |_|  \\____|_| |_|___| .__/     |____/ \\___|\\__, |
                                                |_|                       |_|\033[0m

==================================================================================================

  \033[1;37m▸ Key Parameters:\033[0m

    ▹ \033[33mExecuted By\033[0m       : ${System.getProperty('user.name')}
    ▹ \033[33mRun Date\033[0m          : ${workflow.start.format("yyyy-MM-dd HH:mm 'UTC'")}

                                                                Author: Bo Wang | Version: Beta
==================================================================================================
"""
.stripIndent(true)

workflow {

    // INPUT CHANNEL CREATION

    read_ch = Channel
        .fromPath(params.input_csv)
        .splitCsv(header:true)
        .map { row ->
            def meta = [
                group    : row.group,
                sample_id: row.sample_id,
                donor_id : row.donor_id,
                control  : row.control
            ]
            tuple(meta, file(row.fastq_1), file(row.fastq_2))
        }

    // PREPROCESSING AND ALIGNMENT

    FASTQC(read_ch)

    TRIM_GALORE(read_ch)

    BOWTIE2_BUILD(file(params.fasta))

    BOWTIE2_ALIGN(TRIM_GALORE.out.trimmed_reads, BOWTIE2_BUILD.out.bt2_index)

    // DUPLICATE REMOVAL AND FILTERING

    BAM_PROPER_FILTER(BOWTIE2_ALIGN.out.bam)

    PICARD_MARKDUPLICATES(BAM_PROPER_FILTER.out.bam, file(params.fasta))
    
    BAM_MAPQ20_FILTER(PICARD_MARKDUPLICATES.out.bam)

    // BAM INDEXING & QC STATISTICS

    SAMTOOLS_INDEX(BAM_MAPQ20_FILTER.out.bam)

    SAMTOOLS_STATS(SAMTOOLS_INDEX.out.bam_bai, file(params.fasta))

    SAMTOOLS_IDXSTATS(SAMTOOLS_INDEX.out.bam_bai)

    SAMTOOLS_FLAGSTAT(SAMTOOLS_INDEX.out.bam_bai)

    // DOWNSTREAM ANALYSIS

    def exp_ch = SAMTOOLS_INDEX.out.bam_bai
        .filter { meta, bam, bai -> meta.control.toString() == '0' }
        .map { meta, bam, bai -> 
            tuple(meta.donor_id, meta, bam, bai)
        }

    def ctrl_ch = SAMTOOLS_INDEX.out.bam_bai
        .filter { meta, bam, bai -> meta.control.toString() == '1' }
        .map { meta, bam, bai -> 
            tuple(meta.donor_id, bam, bai)
        }

    def bam_paired_ch = exp_ch.combine(ctrl_ch, by: 0)
        .map { donor_id, exp_meta, exp_bam, exp_bai, ctrl_bam, ctrl_bai ->
            tuple(exp_meta, exp_bam, exp_bai, ctrl_bam, ctrl_bai)
        }

//    bam_paired_ch.view { meta, exp_bam, exp_bai, ctrl_bam, ctrl_bai ->
//        """
//        [Matched Pair]
//        Group     : ${meta.group}
//        Sample ID : ${meta.sample_id}
//        Donor ID  : ${meta.donor_id}
//        Exp BAM   : ${exp_bam}
//        Ctrl BAM  : ${ctrl_bam}
//        Exp BAI   : ${exp_bai}
//        Ctrl BAI  : ${ctrl_bai}
//        """
//    }

    MACS2_CALLPEAK_NARROW(bam_paired_ch)

    MACS2_CALLPEAK_BROAD(bam_paired_ch)

    // SUMMARY REPORT GENERATION

    MULTIQC(
        FASTQC.out.zip.mix(
            FASTQC.out.html,
            TRIM_GALORE.out.trimming_reports,
            TRIM_GALORE.out.fastqc_reports_1,
            TRIM_GALORE.out.fastqc_reports_2,
            BOWTIE2_ALIGN.out.log,
            PICARD_MARKDUPLICATES.out.metrics,
            SAMTOOLS_STATS.out.stats,
            SAMTOOLS_IDXSTATS.out.idxstats,
            SAMTOOLS_FLAGSTAT.out.flagstat
        ).collect(),
        params.report_id
    )
}