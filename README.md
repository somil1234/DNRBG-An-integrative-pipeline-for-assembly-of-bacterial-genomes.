# De-novo-reference-based-guided-genome-assembly-An-integrative-pipeline.

This pipeline is used for de-novo reference-guided assembly, which operates in three phases.

Pre-processing and Contig Generation: The process begins with raw reads in FASTQ format. We first assess the quality of these reads, removing any low-quality sequences and Illumina adapters. The remaining short reads are assembled into contigs.

Selection of best reference: The best reference genome is identified, and the percentage alignment calculation is performed.

Reference-based scaffolding:  Reference-based scaffolding is conducted.



**Installation**

This pipeline is available as a LINUX executable.**


**Dependencies**

This pipeline requires various dependencies.

1. **fastQC**
Available at https://www.bioinformatics.babraham.ac.uk/projects/fastqc/

2. **multiQC**
Available at https://multiqc.info/docs/getting_started/installation/

3. **Trimmomatic**
Available at https://github.com/usadellab/Trimmomatic

4. **FLASH**
Available at https://ccb.jhu.edu/software/FLASH/

5. **Unicycler**
Available at https://github.com/rrwick/Unicycler

6. **QUAST**
Available at https://github.com/ablab/quast

7. **Plentyofbugs**
Available at https://github.com/nickp60/plentyofbugs

8. **Bowtie2**
Available at https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml

9. **AlignGraph**
Available at https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml

10. **BUSCO**
Available at https://busco.ezlab.org/


**USAGE** 

	./dnrgb.sh read1.fastq read2.fastq 
 
 where fastq_1 and fastq_2 are raw sequences, paired-end read one and two, respectively. 


 **KEYNOTES FOR THE USER **

 In our pipeline, we have integrated various other tools to perform de-novo reference-based guided assembly, the requirements for each dependency may vary which can make the installation process a 
 meticulous task. We have tried our best to ensure the following dependencies are installed. Therefore there are various checkpoints in the scripts that will prompt the user if the following programs are 
 installed, if not it will ask for the full path to the required program, wherever it is needed.
 
 Installation of "mash" "skesa" "spades" "seqtk" "unicycler" "plentyofbugs" is far easier in a conda environment. Therefore we try to provide a user with an alternative if they are not installed, the 
 scripts will try to install this for the user in a conda environment "install_env", though some may not be installed the user has to install them manually in the conda environment "install_env". If the 
 required programs are correctly installed and still programmed prompt that "the following program cannot be found" Please add the install program in your path, if all requirements are fulfilled correctly
 the program will skip the installation process and the pipeline will continue.


 **PARAMETERS**

  We have discussed the parameters in detail in our methodology section. However, for convenience, users may consider default but one should keep in mind 
  that the parameters may change according to user requirements, therefore in our scripts we do not provide the flag "--default". Users have to provide parameters interactively.

  **Docker**
  To install docker you can see `https://docs.docker.com/engine/install/ubuntu/`.
  To use docker please use pull command `docker pull somil131/dnrgb_genome_assembly:latest`.

  **Docker Command**
  please make sure that your reference genome directory is named as `reference_genome`.
  You can use the command as mentioned below:-
  
  `docker run -it -v $(pwd):/data -v /Path/to/reference_genome:/data/reference_genome somil131/dnrgb_genome_assembly:latest /data/path/to/Your_files_1.fastq /data/path/to/Your_files_2.fastq`

  
