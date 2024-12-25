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
    quast.py -o "${params.outputDir6}/quast_output" "${params.outputDir5}/assembly/assembly.fasta"
    """
}

// Define plentyofbugs
process plentyofbugs {
    input:
    path quast_result
    path assembler
    path reference_genome
    path trimmomatic_out

    output:
    path "${params.outputDir7}/plentyofbugs_out/*", emit: plentyofbugs_result

    script:
    """

    plentyofbugs --assembler "$assembler" -f "${trimmomatic_out}/output_1P.fq" -r "${trimmomatic_out}/output_2P.fq" -g "$reference_genome" -o "${params.outputDir7}/plentyofbugs_out"
    """
}

// Define process bowtie2_build
process bowtie2_build {
    input:
    path plentyofbugs_result
    path reference_genome

    output:
    path "${params.outputDir8}/bowtie2_index/*", emit: bowtie2_index

    script:
    """
    mkdir -p "${params.outputDir8}/bowtie2_index"
    best_genome=\$(awk '{gsub(/reference_genome\\//, ""); print \$1}' "best_reference")
    genome_file="${reference_genome}/\${best_genome}"
    bowtie2-build -f "\$genome_file" "${params.outputDir8}/bowtie2_index/reference_index"
    """
}

// Define process bowtie2
process bowtie2 {
    input:
    path bowtie2_index
    path trimmomatic_out

    output:
    path "${params.outputDir8}/out.sam"

    script:
    """
    mkdir -p bowtie2_out
    indexPath=\$(find -L ${bowtie2_index} -type f -name '*.rev.1.bt2' | sed 's/\\.rev.1.bt2\$//')
    echo "Using index path: \${indexPath}"
    bowtie2 -x \${indexPath} \
            -1 ${trimmomatic_out}/output_1P.fq \
            -2 ${trimmomatic_out}/output_2P.fq \
            -S "bowtie2_out/out.sam"
    """
}

// Define the process for seqtk
process seqtk {
    input:
    path bowtie2_out
    path trimmomatic_out

    output:
    path "${params.outputDir9}/*", emit: seqtk_out

    script:
    """
    mkdir -p "${params.outputDir9}"
    seqtk seq -A  "${trimmomatic_out}/output_1P.fq" > "${params.outputDir9}/output_1P.fa"
    seqtk seq -A  "${trimmomatic_out}/output_2P.fq" > "${params.outputDir9}/output_2P.fa"
    """
}

// Define the process for padding reads
process pad_read {

    input:
    path forward_read
    path reverse_read
    path pad_read_path
    path reference_based_assembly


    output:
    path "${params.outputDir9}/padded_out1.fa", emit: padded_file1
    path "${params.outputDir9}/padded_out2.fa", emit: padded_file2

    script:
    """
    python "${params.pad_read_path}" "$forward_read" "${reference_based_assembly}/padded_out1.fa" 150
    python "${params.pad_read_path}" "$reverse_read" "${reference_based_assembly}/padded_out2.fa" 150
    """
}

//Define process for AlignGraph
process AlignGraph {

    input:
    path padded_file1
    path padded_file2
    val distancelow
    val distancehigh

    output:
    path "${params.outputDir9}/sample_extendedcontig.fasta", emit: extended_contigs
    path "${params.outputDir9}/sample_remainingcontig.fasta", emit: remaining_contigs

    script:
    """
    best_genome=\$(awk '{print \$1}' "${params.outputDir7}/best_reference")
    AlignGraph --read1 "${params.outputDir9}/padded_out1.fa" \
        --read2 "${params.outputDir9}/padded_out1.fa" \
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
    quast.py -o "${params.outputDir9}/quast_output" "$extended_contigs"
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
      def plentyofbugs_results = plentyofbugs(quast_result, params.assembler, params.reference_genome, trimmomatic_results)

   // Run bowtie2_build process
      def bowtie2_build_results = bowtie2_build(plentyofbugs_results, params.reference_genome)

   // Run bowtie2 process using the emitted bowtie2_index
      def bowtie2_align_result = bowtie2(bowtie2_build_results.bowtie2_index, trimmomatic_results)

   // Run seqtk
      def seqtk_results = seqtk(bowtie2_align_result, trimmomatic_results)

   // Extract specific files from seqtk results
      def forward_read = seqtk_results.seqtk_out.filter { it.name == "output_1P.fa" }
      def reverse_read = seqtk_results.seqtk_out.filter { it.name == "output_2P.fa" }

   // Run the pad_read process
      def pad_read_results = pad_read(forward_read, reverse_read, params.pad_read_path, params.outputDir9)

   // Run AlignGraph
      def AlignGraph_results = AlignGraph(params.distancelow, params.distancehigh, pad_read_results.padded_file1, pad_read_results.padded_file2)

   // Run quast2 for AlignGraph
      def quast2_results = quast2(AlignGraph_results.extended_contigs)

   // Run busco
      busco(quast2_results, params.busco_lineage)
}
