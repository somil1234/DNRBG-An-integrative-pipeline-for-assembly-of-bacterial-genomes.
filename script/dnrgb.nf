#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Define parameters read1 and read2
params.forward_read = null
params.reverse_read = null

// Define parameters for trimmomatic
params.thread = 4
params.phred = 33
params.PATH_TO_ADAPTER_CONTAM_FILE = 'Path/to/your/adapter/file'
params.leading = 3
params.trailing = 3
params.slidingwindow = '4:15'
params.minlength = 36

// Define parameters for flash
params.max_overlap = 150

// Define parameters for plentyofbugs
params.assembler = 'path/to/skesa'
params.reference_genome = 'path/to/your/reference/genome/dir'

// Define input parameter path for pad reads
params.pad_read_path = 'path/to/your/pad_reads.py'
params.pad_read_value = 150

// Define input parameters for AlignGraph
params.distancelow = 100
params.distancehigh = 1000

// Define input parameter for BUSCO
params.busco_lineage = 'bacteria_odb10'

// Define output directories
params.outputDir1 = "fastqc_out"
params.outputDir2 = "multiqc_out"
params.outputDir3 = "trimmomatic_out"
params.outputDir4 = "flash_out"
params.outputDir5 = "unicycler_out"
params.outputDir6 = "quast_out"
params.outputDir7 = "plentyofbugs_out"
params.outputDir8 = "bowtie2_out"
params.outputDir9 = "reference_based_assembly"
params.outputDir10 = "busco"

// Define the first process (FastQC)
process fastqc {

    input:
    path forward_read
    path reverse_read

    output:
    path "${params.outputDir1}"

    script:
    """
    mkdir -p fastqc_out
    fastqc -o fastqc_out -f fastq "$forward_read" "$reverse_read"
    """
}

// Define the second process (MultiQC)
process multiqc {

    input:
    path fastqc_out

    output:
    path "${params.outputDir2}"

    script:
    """
    mkdir -p multiqc_out
    multiqc "$fastqc_out" -o ${params.outputDir2}
    """
}

// Define the third process (Trimmomatic)
process trimmomatic {

    input:
    path forward_read
    path reverse_read
    val thread
    val phred
    path PATH_TO_ADAPTER_CONTAM_FILE
    val leading
    val trailing
    val slidingwindow
    val minlength

    output:
    path "${params.outputDir3}"

    script:
    """
    mkdir -p ${params.outputDir3}
    trimmomatic PE -threads "$thread" -phred"$phred" "$forward_read" "$reverse_read" \
        "${params.outputDir3}/output_1P.fq" "${params.outputDir3}/output_1U.fq" \
        "${params.outputDir3}/output_2P.fq" "${params.outputDir3}/output_2U.fq" \
        ILLUMINACLIP:"$PATH_TO_ADAPTER_CONTAM_FILE":2:30:10 LEADING:"$leading" \
        TRAILING:"$trailing" SLIDINGWINDOW:"$slidingwindow" MINLEN:"$minlength"
    """
}

// Define the fourth process (FLASH)
process flash {

    input:
    path trimmomatic_out
    val max_overlap

    output:
    path "${params.outputDir4}"

    script:
    """
    mkdir -p flash_out
    flash --max-overlap "$max_overlap" \
        "${params.outputDir3}/output_1P.fq" "${params.outputDir3}/output_2P.fq" \
        -d ${params.outputDir4}
    """
}

// Define the fifth process (Unicycler)
process unicycler {

    input:
    path trimmomatic_out
    path flash_out

    output:
    path "${params.outputDir5}"

    script:
    """
    mkdir -p unicycler_out
    unicycler -1 "${params.outputDir3}/output_1P.fq" -2 "${params.outputDir3}/output_2P.fq" \
        -s "${params.outputDir4}/out.extendedFrags.fastq" -o "${params.outputDir5}/assembly"
    """
}

// Define the sixth process (Quast)
process quast {

    input:
    path unicycler_out

    output:
    path "${params.outputDir6}"

    script:
    """
    mkdir -p quast_out
    quast -o "${params.outputDir6}/quast_output" "${params.outputDir5}/assembly/assembly.fasta"
    """
}

// Define the seventh process (Plentyofbugs)
process plentyofbugs {

    input:
    path quast_result
    path assembler
    path reference_genome

    output:
    path "${params.outputDir7}"

    script:
    """
    mkdir -p plentyofbugs_out
    plentyofbugs --assembler "$assembler" -f "${params.outputDir3}/output_1P.fq" \
        -r "${params.outputDir3}/output_2P.fq" -g "$reference_genome" \
        -o "${params.outputDir7}/plentyofbugs_out"
    """
}

// Define the process for Bowtie2 build
process bowtie2_build {

    input:
    path "${params.outputDir7}/best_reference"

    output:
    path("${params.outputDir8}/reference_index*.bt2"), emit: bowtie2_indices

    script:
    """
    mkdir -p ${params.outputDir8}

    best_genome=\$(awk '{print \$1}' "${best_reference}")

    bowtie2-build -f "\${best_genome}" "${params.outputDir8}/reference_index"
    """
}

// Define the process for Bowtie2 alignment
process bowtie2 {

    input:
    path "${params.outputDir8}/reference_index"
    path "${params.outputDir3}"

    output:
    path "${params.outputDir8}"

    script:
    """
    bowtie2 -x "${params.outputDir8}/reference_index" \
        -1 "${params.outputDir3}/output_1P.fq" -2 "${params.outputDir3}/output_2P.fq" \
        -S "${params.outputDir8}/out.sam"
    """
}

// Define the process for seqtk
process seqtk {

    input:
    path "${params.outputDir3}/output_1P.fq" // Input for forward reads
    path "${params.outputDir3}/output_2P.fq" // Input for reverse reads

    output:
    path "output_1P.fa", emit: forward_fasta // Forward reads converted to FASTA
    path "output_2P.fa", emit: reverse_fasta // Reverse reads converted to FASTA

    script:
    """
    mkdir -p ${params.outputDir8}
    seqtk seq -A "${params.outputDir3}/output_1P.fq" > "${params.outputDir9}/output_1P.fa"
    seqtk seq -A "${params.outputDir3}/output_1P.fq" > "${params.outputDir9}/output_2P.fa"
    """
}

// Define the process for padding reads
process pad_read {

    input:
    path seqtk_results
    path pad_read_path
    val pad_read_value
    path "${params.outputDir9}"

    output:
    path "${params.outputDir9}/padded_out1.fa", emit: padded_out1
    path "${params.outputDir9}/padded_out2.fa", emit: padded_out2

    script:
    """
    python "$pad_read_path"  "${params.outputDir9}/output_1P.fa" "${params.outputDir9}/padded_out1.fa" "$pad_read_value"
    python "$pad_read_path"  "${params.outputDir9}/output_2P.fa" "${params.outputDir9}/padded_out2.fa" "$pad_read_value"
    """
}

process AlignGraph {

    input:
    val distancelow
    val distancehigh
    path padded_out1
    path padded_out2

    output:
    path "${params.outputDir9}/sample_extendedcontig.fasta", emit: extended_contigs
    path "${params.outputDir9}/sample_remainingcontig.fasta", emit: remaining_contigs

    script:
    """
    best_genome=\$(awk '{print \$1}' "${params.outputDir7}/best_reference")
    AlignGraph --read1 "$padded_out1" \
        --read2 "$padded_out2" \
        --contig "${params.outputDir7}/plentyofbugs_out/assembly/contigs.fasta" \
        --genome "\$best_genome" --distanceLow "$distancelow" --distanceHigh "$distancehigh" \
        --extendedContig "${params.outputDir9}/sample_extendedcontig.fasta" \
        --remainingContig "${params.outputDir9}/sample_remainingcontig.fasta"
    """
}

// Define the process for quast2 (final Quast)
process quast2 {

    input:
    path extended_contigs

    output:
    path "${params.outputDir9}/quast_output"

    script:
    """
    mkdir -p ${params.outputDir9}/quast_output
    quast -o "${params.outputDir9}/quast_output" "$extended_contigs"
    """
}

// Define the process for BUSCO
process busco {

    input:
    path busco_lineage
    path extended_contigs

    output:
    path "${params.outputDir10}/busco_output"

    script:
    """
    mkdir -p ${params.outputDir10}
    busco -i "$extended_contigs" -o "${params.outputDir10}/busco_output" -l "$busco_lineage" --mode genome
    """
}

 workflow {
    // Run fastqc  and get the output
       def fastqc_result = fastqc(params.forward_read, params.reverse_read)

    // Run MultiQC on the FastQC output directory
       multiqc(fastqc_result) // Pass the FastQC output directory to MultiQC

    // Run trimmomatic on multiqc output dir
      def trimmomatic_results = trimmomatic(params.forward_read, params.reverse_read, params.thread, params.phred, params.PATH_TO_ADAPTER_CONTAM_FILE, params.leading, params.trailing, params.slidingwindow, params.minlength)

   // Run flash on trimmomatic dir
      def flash_results = flash(trimmomatic_results, params.max_overlap)

   // Run unicycler
      def unicycler_results = unicycler(trimmomatic_results, flash_results)

   // Run quast
      def quast_result = quast(unicycler_results)

   // Run plentyofbugs
      def plentyofbugs_results = plentyofbugs(quast_result, params.assembler, params.reference_genome)

   // Run bowtie2_build
      def bowtie2_build_results = bowtie2_build(plentyofbugs_results)

   // Run bowtie2
      def bowtie2_align_result = bowtie2(bowtie2_build_results, params.outputDir3)

   // Run seqtk
      def seqtk_results = seqtk(bowtie2_align_result, params.outputDir3)

   // Run pad_read
      def (padded_out1, padded_out2) = pad_read(seqtk_results, params.pad_read_path, params.pad_read_value)

   // Run AlignGraph
      def AlignGraph_results = AlignGraph(params.distancelow, params.distancehigh, padded_out1, padded_out2)

   // Run quast2 for AlignGraph
      def quast2_results = quast2(AlignGraph_results.extended_contigs)

   // Run busco
      busco(quast2_results, params.busco_lineage)
}
