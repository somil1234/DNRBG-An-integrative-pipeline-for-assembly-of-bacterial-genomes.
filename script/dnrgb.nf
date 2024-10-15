nextflow.enable.dsl=2

// Define input parameters
params.inputFile1 = null
params.inputFile2 = null
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
params.scriptPath = null // To take arguments through command line

process runDNRGB {
    input:
    path inputFile1
    path inputFile2

    output:
    path "${params.outputDir1}/output1.txt" // Change to your desired output
    path "${params.outputDir2}/output2.txt" // Change to your desired output
    path "${params.outputDir3}/output3.txt" // Change to your desired output
    path "${params.outputDir4}/output4.txt" // Change to your desired output
    path "${params.outputDir5}/output5.txt" // Change to your desired output
    path "${params.outputDir6}/output6.txt" // Change to your desired output
    path "${params.outputDir7}/output7.txt" // Change to your desired output
    path "${params.outputDir8}/output8.txt" // Change to your desired output
    path "${params.outputDir9}/output9.txt" // Change to your desired output
    path "${params.outputDir10}/output10.txt" // Change to your desired output

    script:
    """
    bash ${params.scriptPath} "${inputFile1}" "${inputFile2}"
    """
 }

workflow {
    runDNRGB(params.inputFile1, params.inputFile2)
 }
