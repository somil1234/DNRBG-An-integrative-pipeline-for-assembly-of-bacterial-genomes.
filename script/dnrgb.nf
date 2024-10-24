#!/usr/bin/env nextflow

nextflow.enable.dsl=2

//Define parameters read1 and read2
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
params.assembler = 'skesa'
params.reference_genome = 'path/to/your/reference/genome/dir'

// Define output directory
params.outputDir1 = "fastqc_out"
params.outputDir2 = "multiqc_out"
params.outputDir3 = "trimmomatic_out"
params.outputDir4 = "flash_out"
params.outputDir5 = "unicycler_out"
params.outputDir6 = "quast_out"
params.outputDir7 = "plentyofbugs_out"

//Define the first Process
process fastqc {

        input:
        path  forward_read
        path  reverse_read

        output:
        path  "${params.outputDir1}"

        script:
        """
        mkdir -p fastqc_out
        fastqc -o fastqc_out -f fastq "$forward_read" "$reverse_read"
        """
  }


// Define second process
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

// Define third process for trimmomatic
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
          trimmomatic PE -threads "$thread" -phred"$phred" "$forward_read" "$reverse_read" "${params.outputDir3}/output_1P.fq" "${params.outputDir3}/output_1U.fq" "${params.outputDir3}/output_2P.fq" "${params.outputDir3}/output_2U.fq" ILLUMINACLIP:"$PATH_TO_ADAPTER_CONTAM_FILE":2:30:10 LEADING:"$leading" TRAILING:"$trailing" SLIDINGWINDOW:"$slidingwindow" MINLEN:"$minlength"
          """
}


//Definr fourth process
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

// Define fifth process

process unicycler {

           input:
           path trimmomatic_out
           path flash_out

           output:
           path "${params.outputDir5}"

           script:
           """
           mkdir -p  unicycler_out
           unicycler -1 "${params.outputDir3}/output_1P.fq" -2 "${params.outputDir3}/output_2P.fq" -s "${params.outputDir4}/out.extendedFrags.fastq" -o "${params.outputDir5}/assembly"
           """

}

// Define sixth process for quast
process quast {

            input:
            path unicycler_out

            output:
            path "${params.outputDir6}"

            script:
            """
            mkdir -p  quast_out
            quast -o  "${params.outputDir6}/quast_output" "${params.outputDir5}/assembly/assembly.fasta"
            """

}

// Define seventh process for plentyofbugs
process plentyofbugs {

             input:
             path assembler
             path reference_genome

             output:
             path "${params.outputDir7}"

             script:
             """
             mkdir -p plentyofbugs_out
             plentyofbugs --assembler "$assembler" -f "${params.outputDir3}/output_1P.fq" -r "${params.outDir3}/output_2P.fq" -g "$reference_genome" -o "${params.outputDir7}/plentyofbugs_out"
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
    plentyofbugs(quast_result, params.assembler, params.reference_genome)
  }
