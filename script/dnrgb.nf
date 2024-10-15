nextflow.enable.dsl=2

// Define parameters for the input files from the command line
params.inputFile1 = null
params.inputFile2 = null

process runDNRGB {
    // Define inputs for the script
    input:
    path inputFile2  // Expecting inputFile2 from the command line

    // Define the expected output directories from the script
    output:
    path "fastqc_out/*", 
         path "multiqc_out/*", 
         path "trimmomatic_out/*", 
         path "flash_out/*", 
         path "unicycler_out/*", 
         path "quast_out/*", 
         path "plentyofbugs_out/*", 
         path "bowtie2_out/*", 
         path "reference_based_assembly/*" // Adjust these to match your actual output files

    // Execute the Bash script with both input files passed as parameters
    script:
    """
    bash dnrgb.sh ${params.inputFile1} $inputFile2
    """
}

// Define the workflow
workflow {
    // Check if the user provided both input files
    if (params.inputFile1 == null || params.inputFile2 == null) {
        error "Please provide both input files using the '-inputFile1' and '-inputFile2' parameters."
    }

    // Run the DNRGB process with the second input file
    runDNRGB(params.inputFile2)
}
