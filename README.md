# De-novo-reference-based-guided-genome-assembly-An-integrative-pipeline.

This pipeline is used for de-novo reference-guided assembly, which operates in three phases.

Pre-processing and Contig Generation: The process begins with raw reads in FASTQ format. We first assess the quality of these reads, removing any low-quality sequences and Illumina adapters. The remaining short reads are assembled into contigs.

Selection of best reference: The best reference genome is identified, and the percentage alignment calculation is performed.

Reference-based scaffolding:  Reference-based scaffolding is conducted.

######################################################################

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

6. **OUAST**
Available at https://github.com/ablab/quast

7. **Plentyofbugs**
Available at https://github.com/nickp60/plentyofbugs

8. **Bowtie2**
Available at https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml

9. **AlignGraph**
Available at https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml

10. **BUSCO**
Available at https://busco.ezlab.org/

####################################################################

**USAGE** 

	./genome_assembly fastq_1 fastq_2 
 
 where fastq_1 and fastq_2 are raw sequences, paired-end read one and two, respectively. 

 **Key notes**
 

   
